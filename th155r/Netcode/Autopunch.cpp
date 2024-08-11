#include "Autopunch.h"

const wchar_t relay_host[] = L"delthas.fr";
const int relay_port = 14763;
const char punch_payload[] = {0};

struct sockaddr_in relay_addr;
bool started;
HANDLE singleton_mutex;

struct socket_data *sockets;
size_t sockets_len;
size_t sockets_cap;
HANDLE sockets_mutex;

HANDLE relay_thread;
bool relay_close;

int WSAAPI my_recvfrom(
  SOCKET s,
  LPWSABUF lpBuffers,
  DWORD dwBufferCount,
  LPDWORD lpNumberOfBytesRecvd,
  LPDWORD lpFlags,
  sockaddr *lpFrom,
  LPINT lpFromlen,
  LPWSAOVERLAPPED lpOverlapped,
  LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine
){
	struct socket_data *socket_data = get_socket_data(s);
	if (!socket_data) {
		log_printf("ignoring unknown socket: socket=%zu\n", s);
		return WSARecvFrom(s, lpBuffers, dwBufferCount, lpNumberOfBytesRecvd, lpFlags,lpFrom,lpFromlen,lpOverlapped,lpCompletionRoutine); // TODO error?
	}

	struct sockaddr_in from_backing;
	struct sockaddr_in *from;
	if (!lpFrom) {
		from = &from_backing;
	} else {
		from = (struct sockaddr_in *)lpFrom;
	}
	int fromlen_backing;
	int *fromlen;
	if (!lpFromlen) {
		fromlen = &fromlen_backing;
		fromlen_backing = sizeof(from_backing);
	} else {
		fromlen = lpFromlen;
	}
	char buf_backing[8];
	char *buf;
	if (*lpFromlen < 8) {
		buf = buf_backing;
	} else {
		buf = lpBuffers->buf;
	}
	log_printf("starting receive: socket=%zu len=%d flags=%d\n", s, lpFromlen, lpFlags);
	while (true){
		int n = WSARecvFrom(s, lpBuffers,dwBufferCount, *lpNumberOfBytesRecvd > 8 ? lpNumberOfBytesRecvd : (DWORD *)8, lpFlags,(struct sockaddr *)&from,fromlen,lpOverlapped,lpCompletionRoutine); // TODO error?
		if (n < 0) {
			int err = WSAGetLastError();
			if (err == WSAECONNRESET) { // ignore connection reset errors (can happen if relay is down)
				log_printf("recvfrom returned WSAECONNRESET, skipping\n");
				continue;
			}
			log_printf("recvfrom returned error: err=%d\n", err);
			return n;
		}
		log_printf("recvfrom success: n=%d from=", from, n);
		if (from->sin_addr.s_addr == relay_addr.sin_addr.s_addr && from->sin_port == relay_addr.sin_port) {
			if (n != 8) {
				log_printf("received invalid relay payload: invalid size n=%d\n", n);
				continue;
			}
			WaitForSingleObject(socket_data->mutex, INFINITE);
			clock_t now = clock();
			u_short port_internal = *((u_short *)(&buf[0]));
			u_short port_nat = *((u_short *)(&buf[2]));
			u_long addr = *(u_long *)(&buf[4]);
			log_printf("received mapping from relay: socket=%zu internal_port=%d nat_port=%d\n", s, ntohs(port_internal), ntohs(port_nat));
			for (int j = 0; j < socket_data->mappings_len; ++j) {
				struct mapping *mapping = &socket_data->mappings[j];
				if (mapping->addr.sin_addr.s_addr != addr) {
					continue;
				}
				if (mapping->port != port_internal) {
					continue;
				}
				log_printf("updating mapping port: socket=%zu new_nat_port=%d internal_port=%d for \n", &mapping->addr, s, ntohs(port_nat), ntohs(port_internal));
				mapping->addr.sin_port = port_nat;
				mapping->last_refresh = now;
				mapping->last_send = 0;
				goto outer;
			}
			if (socket_data->mappings_len == socket_data->mappings_cap) {
				socket_data->mappings_cap = socket_data->mappings_cap ? socket_data->mappings_cap * 2 : 8;
				socket_data->mappings = (mapping*)realloc(socket_data->mappings, socket_data->mappings_cap * sizeof(socket_data->mappings[0]));
			}
			socket_data->mappings[socket_data->mappings_len++] = {
				.addr = {
					.sin_family = AF_INET,
					.sin_port = port_nat,
					.sin_addr = {addr},
				},
				.port = port_internal,
				.last_send = 0,
				.last_refresh = now,
				.refresh = true,
			};
			log_printf("adding mapping: socket=%zu mappings_len=%zu mappings_cap=%zu internal_port=%d for \n",&socket_data->mappings[socket_data->mappings_len - 1].addr, s, socket_data->mappings_len, socket_data->mappings_cap, ntohs(port_internal));
		outer:;
			ReleaseMutex(socket_data->mutex);
			continue;
		}
		WaitForSingleObject(socket_data->mutex, INFINITE);
		for (int i = 0; i < socket_data->transient_peers_len; ++i) {
			struct transient_peer *peer = &socket_data->transient_peers[i];
			if (peer->addr.sin_addr.s_addr != from->sin_addr.s_addr) {
				continue;
			}
			if (peer->addr.sin_port != from->sin_port) {
				log_printf("transient port mismatch: received_from=%d for \n", &peer->addr, ntohs(from->sin_port));
				continue;
			}
			socket_data->transient_peers[i--] = socket_data->transient_peers[--socket_data->transient_peers_len];

			if (socket_data->mappings_len == socket_data->mappings_cap) {
				socket_data->mappings_cap = socket_data->mappings_cap ? socket_data->mappings_cap * 2 : 8;
				socket_data->mappings = (mapping*)realloc(socket_data->mappings, socket_data->mappings_cap * sizeof(socket_data->mappings[0]));
			}
			clock_t now = clock();
			socket_data->mappings[socket_data->mappings_len++] = {
				.addr = {
					.sin_family = AF_INET,
					.sin_port = from->sin_port,
					.sin_addr = {from->sin_addr.s_addr},
				},
				.port = from->sin_port,
				.last_send = now,
				.last_refresh = now,
				.refresh = false,
			};
			log_printf("received transient, adding as mapping: socket=%zu mappings_len=%zu mappings_cap=%zu for \n", from, s, socket_data->mappings_len,socket_data->mappings_cap);
			break;
		}

		if (n == sizeof(punch_payload) && !memcmp(punch_payload, buf, n)) {
			log_printf("skipping punch payload\n");
			ReleaseMutex(socket_data->mutex);
			continue;
		}

		for (int i = 0; i < socket_data->mappings_len; ++i) {
			struct mapping *mapping = &socket_data->mappings[i];
			if (mapping->addr.sin_addr.s_addr != from->sin_addr.s_addr) {
				continue;
			}
			if (mapping->addr.sin_port != from->sin_port) {
				log_printf("mapping port mismatch: received_from=%d for \n", &mapping->addr, ntohs(from->sin_port));
				continue;
			}
			log_printf("matched mapping, injecting internal_port=%d for \n", from, ntohs(mapping->port));
			from->sin_port = mapping->port;
			break;
		}
		ReleaseMutex(socket_data->mutex);

		log_printf("received data: n=%d buf[0]=%d from \n", from, n, buf[0]);
		if (lpBuffers->buf != buf) {
			memcpy(lpBuffers->buf, buf, n);
		}
		return n;
	}
}

int WSAAPI my_sendto(
	SOCKET s,
	LPWSABUF lpBuffers,
	DWORD dwBufferCount,
	LPDWORD lpNumberOfBytesSent,
	DWORD dwFlags,
	struct sockaddr *lpTo,
	int iTolen, 
	LPWSAOVERLAPPED lpOverlapped,
	LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine)
{
	if (lpTo->sa_family != AF_INET){
		return WSASendTo(s,lpBuffers,dwBufferCount,lpNumberOfBytesSent,dwFlags,lpTo,iTolen,lpOverlapped,lpCompletionRoutine);
	}
	struct socket_data *socket_data = get_socket_data(s);
	if(!socket_data){
		return WSASendTo(s,lpBuffers,dwBufferCount,lpNumberOfBytesSent,dwFlags,lpTo,iTolen,lpOverlapped,lpCompletionRoutine);
	}
	struct sockaddr_in *to = (struct sockaddr_in *)lpTo;
	WaitForSingleObject(socket_data->mutex,INFINITE);
	for (int i = 0; i < socket_data->mappings_len; ++i) {
		struct mapping *_mapping = &socket_data->mappings[i];
		if (_mapping->addr.sin_addr.s_addr != to->sin_addr.s_addr) {
			continue;
		}
		if (_mapping->port != to->sin_port) {
			log_printf("mapping port mismatch: mapping_internal_port=%d for \n", to, ntohs(_mapping->port));
			continue;
		}
		clock_t now = clock();
		_mapping->last_refresh = now;
		_mapping->last_send = now;
		log_printf("matched mapping, injecting nat_port=%d for \n", to, ntohs(_mapping->addr.sin_port));
		int r = WSASendTo(s,lpBuffers,dwBufferCount,lpNumberOfBytesSent,dwFlags,(struct sockaddr *)_mapping,iTolen,lpOverlapped,lpCompletionRoutine);
		ReleaseMutex(socket_data->mutex);
		return r;
	}
	int r = WSASendTo(s,lpBuffers,dwBufferCount,lpNumberOfBytesSent,dwFlags,lpTo,iTolen,lpOverlapped,lpCompletionRoutine);

	int refresh = -1;
	clock_t now = clock();
	for (int i = 0; i < socket_data->transient_peers_len; ++i) {
		struct transient_peer *peer = &socket_data->transient_peers[i];
		if ((now - peer->last) / CLOCKS_PER_SEC > 10) { // transient peer timeout
			socket_data->transient_peers[i--] = socket_data->transient_peers[--socket_data->transient_peers_len];
			continue;
		}
		if (peer->addr.sin_addr.s_addr != to->sin_addr.s_addr) {
			continue;
		}
		if (peer->addr.sin_port != to->sin_port) {
			log_printf("transient port mismatch: send_to=%d for \n", &peer->addr, ntohs(to->sin_port));
			continue;
		}
		refresh = (now - peer->last) * 1000 / CLOCKS_PER_SEC > 500;
		if (refresh) {
			peer->last = now;
		}
		log_printf("transient found: refresh=%d now=%ld last=%ld for \n", to, refresh, now, peer->last);
		break;
	}
	if (refresh == -1) {
		if (socket_data->transient_peers_len == socket_data->transient_peers_cap) {
			socket_data->transient_peers_cap = socket_data->transient_peers_cap ? socket_data->transient_peers_cap * 2 : 8;
			socket_data->transient_peers = (transient_peer*)realloc(socket_data->transient_peers, socket_data->transient_peers_cap * sizeof(socket_data->transient_peers[0]));
		}
		socket_data->transient_peers[socket_data->transient_peers_len++] = {
			.addr = {
				.sin_family = AF_INET,
				.sin_port = to->sin_port,
				.sin_addr = {to->sin_addr.s_addr},
			},
			.last = now,
		};
		refresh = true;
		log_printf("adding transient: len=%zu cap=%zu for \n", to, socket_data->transient_peers_len, socket_data->transient_peers_cap);
	}
	if (refresh) {
		char relay_buf[] = {((char *)&(socket_data->port))[0], ((char *)&(socket_data->port))[1], to->sin_addr.S_un.S_un_b.s_b1, to->sin_addr.S_un.S_un_b.s_b2,
			to->sin_addr.S_un.S_un_b.s_b3, to->sin_addr.S_un.S_un_b.s_b4, ((char *)&(to->sin_port))[0], ((char *)&(to->sin_port))[1]};
		WSABUF buf;
		buf.buf = relay_buf;
		buf.len = sizeof(relay_buf);
		WSASendTo(s, &buf,sizeof(relay_buf),NULL,dwFlags, (struct sockaddr *)&relay_addr, sizeof(relay_addr),lpOverlapped,lpCompletionRoutine);
		//WSASendTo(s,lpBuffers,dwBufferCount,lpNumberOfBytesSent,dwFlags,lpTo,iTolen,lpOverlapped,lpCompletionRoutine);
		log_printf("refreshing transient, send payload: socket=%zu len=%zu cap=%zu for \n", to, socket_data->s, socket_data->transient_peers_len,
			socket_data->transient_peers_cap);
	}
	ReleaseMutex(socket_data->mutex);
	return r;
}

int WSAAPI my_send(
    SOCKET s,
    LPWSABUF lpBuffers,
    DWORD dwBufferCount,
    LPDWORD lpNumberOfBytesSent,
    DWORD dwFlags,
    LPWSAOVERLAPPED lpOverlapped,
    LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine)
{
    struct socket_data *socket_data = get_socket_data(s);
    if (!socket_data) {
        return WSASend(s, lpBuffers, dwBufferCount, lpNumberOfBytesSent, dwFlags, lpOverlapped, lpCompletionRoutine);
    }

    WaitForSingleObject(socket_data->mutex, INFINITE);
    
    clock_t now = clock();
    for (int i = 0; i < socket_data->mappings_len; ++i) {
        struct mapping *_mapping = &socket_data->mappings[i];
        _mapping->last_refresh = now;
        _mapping->last_send = now;
    }

    int r = WSASend(s, lpBuffers, dwBufferCount, lpNumberOfBytesSent, dwFlags, lpOverlapped, lpCompletionRoutine);

    int refresh = -1;
    now = clock();
    for (int i = 0; i < socket_data->transient_peers_len; ++i) {
        struct transient_peer *peer = &socket_data->transient_peers[i];
        if ((now - peer->last) / CLOCKS_PER_SEC > 10) { // transient peer timeout
            socket_data->transient_peers[i--] = socket_data->transient_peers[--socket_data->transient_peers_len];
            continue;
        }
        refresh = (now - peer->last) * 1000 / CLOCKS_PER_SEC > 500;
        if (refresh) {
            peer->last = now;
        }
        break;
    }
    
    if (refresh == -1) {
        if (socket_data->transient_peers_len == socket_data->transient_peers_cap) {
            socket_data->transient_peers_cap = socket_data->transient_peers_cap ? socket_data->transient_peers_cap * 2 : 8;
            socket_data->transient_peers = (transient_peer*)realloc(socket_data->transient_peers, socket_data->transient_peers_cap * sizeof(socket_data->transient_peers[0]));
        }
        socket_data->transient_peers[socket_data->transient_peers_len++] = {
            .last = now,
        };
        refresh = true;
    }
    
    if (refresh) {
        char relay_buf[] = {((char *)&(socket_data->port))[0], ((char *)&(socket_data->port))[1]};
        WSABUF buf;
        buf.buf = relay_buf;
        buf.len = sizeof(relay_buf);
        WSASend(s, &buf, sizeof(relay_buf), NULL, dwFlags, lpOverlapped, lpCompletionRoutine);
    }

    ReleaseMutex(socket_data->mutex);
    return r;
}

int WSAAPI my_bind(SOCKET s, const struct sockaddr *name, int namelen) {
	if (name) {
		log_printf("starting bind: socket=%zu, family=%d, address=%s\n", s, name->sa_family, inet_ntoa(((const struct sockaddr_in *)name)->sin_addr));
	} else {
		log_printf("starting bind: socket=%zu without address\n", s);
	}
	int r = bind(s, name, namelen);
	if (r) {
		auto err = WSAGetLastError();
		log_printf("bind failed: r=%d error=%d\n", r,err);
		return r;
	}
	struct sockaddr_in local_addr;
	socklen_t local_addr_len = sizeof(local_addr);
	if (getsockname(s, (struct sockaddr *)&local_addr, &local_addr_len)) {
		log_printf("getsockname failed: err=%d\n", WSAGetLastError());
		return r;
	}
	if (local_addr.sin_family != AF_INET) {
		log_printf("ignoring socket with ignored family: family=%d\n", local_addr.sin_family);
		return r;
	}
	log_printf("bound local port: socket=%zu local_port=%d\n", s, ntohs(local_addr.sin_port));
	WaitForSingleObject(sockets_mutex, INFINITE);
	if (sockets_len == sockets_cap) {
		sockets_cap = sockets_cap ? sockets_cap * 2 : 8;
		sockets = (socket_data*)realloc(sockets, sockets_cap * sizeof(sockets[0]));
	}
	sockets[sockets_len++] = (struct socket_data){
		.s = s,
		.mutex = CreateMutex(NULL, FALSE, NULL),
		.port = local_addr.sin_port,
	};
	log_printf("adding socket: socket=%zu local_port=%d\n", s, ntohs(local_addr.sin_port));
	ReleaseMutex(sockets_mutex);
	return r;
}

int WINAPI my_closesocket(SOCKET s) {
	struct socket_data *socket_data = get_socket_data(s);
	if (!socket_data) {
		log_printf("ignoring unknown socket: socket=%zu\n", s);
		return closesocket(s);
	}
	log_printf("starting close: socket=%zu\n", s);
	int r = closesocket(s);
	WaitForSingleObject(socket_data->mutex, INFINITE);
	socket_data->closed = true;
	ReleaseMutex(socket_data->mutex);
	return r;
}

DWORD WINAPI relay(void *data) {
	log_printf("relay start\n");
	while (true) {
		WaitForSingleObject(sockets_mutex, INFINITE);
		if (relay_close) {
			ReleaseMutex(sockets_mutex);
			return 0;
		}
		clock_t now = clock();
		if (relay_addr.sin_addr.s_addr == 0) {
			relay_addr.sin_addr.s_addr = get_relay_ip();
		}
		for (int i = 0; i < sockets_len; ++i) {
			struct socket_data *socket_data = &sockets[i];
			WaitForSingleObject(socket_data->mutex, INFINITE);
			if (socket_data->closed) {
				log_printf("removing closed socket: socket=%zu closed=%d mappings=%zu mappings_len=%zu mappings_cap=%zu sockets_len=%zu sockets_cap=%zu\n", socket_data->s,
					socket_data->closed, (size_t)socket_data->mappings, socket_data->mappings_len, socket_data->mappings_cap, sockets_len, sockets_cap);
				ReleaseMutex(socket_data->mutex);
				CloseHandle(socket_data->mutex);
				free(socket_data->mappings);
				free(socket_data->transient_peers);
				sockets[i--] = sockets[--sockets_len];
				continue;
			}
			char buf[] = {((char *)&(socket_data->port))[0], ((char *)&(socket_data->port))[1]};
			log_printf("sending to relay bound socket: socket=%zu socket_i=%d local_port=%u\n", socket_data->s, i, ntohs(socket_data->port));
			sendto(socket_data->s, buf, sizeof(buf), 0, (struct sockaddr *)&relay_addr, sizeof(relay_addr));
			for (int j = 0; j < socket_data->mappings_len; ++j) {
				struct mapping *mapping = &socket_data->mappings[j];
				log_printf("mapping process: socket=%zu socket_i=%d mapping_j=%d\n", socket_data->s, i, j);
				clock_t wait_refresh = (now - mapping->last_refresh) / CLOCKS_PER_SEC;
				if (wait_refresh > 10) { // drop old mapping
					log_printf("mapping timeout: socket=%zu socket_i=%d mapping_j=%d wait_refresh=%ld\n", socket_data->s, i, j, wait_refresh);
					socket_data->mappings[j--] = socket_data->mappings[--socket_data->mappings_len];
					continue;
				}
				clock_t wait_send = (now - mapping->last_send) / CLOCKS_PER_SEC;
				if (mapping->refresh && (mapping->last_send == 0 || wait_send >= 1)) { // refresh mapping
					log_printf("mapping refresh, send payload: socket=%zu socket_i=%d mapping_j=%d wait_send=%ld\n", socket_data->s, i, j, wait_send);
					sendto(socket_data->s, punch_payload, sizeof(punch_payload), 0, (struct sockaddr *)&mapping->addr, sizeof(mapping->addr));
					mapping->last_send = clock();
				}
			}
			ReleaseMutex(socket_data->mutex);
		}
		ReleaseMutex(sockets_mutex);
		if (relay_close) {
			return 0;
		}
		Sleep(500);
	}
}

u_long get_relay_ip() {
	ADDRINFOW hints;
	ZeroMemory(&hints, sizeof(hints));
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_DGRAM;
	hints.ai_protocol = IPPROTO_UDP;
	ADDRINFOW *result = NULL;
	DWORD r = GetAddrInfoW(relay_host, NULL, &hints, &result);
	if (r != 0) {
		log_printf("getaddrinfow failed: %lu\n", r);
		return 0;
	}
	for (ADDRINFOW *ptr = result; ptr != NULL; ptr = ptr->ai_next) {
		if (ptr->ai_family == AF_INET) {
			u_long address = ((struct sockaddr_in *)ptr->ai_addr)->sin_addr.s_addr;
			log_printf("getaddrinfow success: \n", ((struct sockaddr_in *)ptr->ai_addr));
			FreeAddrInfoW(result);
			return address;
		}
	}
	FreeAddrInfoW(result);
	log_printf("getaddrinfow no dns results\n");
	return 0;
}

struct socket_data *get_socket_data(SOCKET s) {
	struct socket_data *socket_data = NULL;
	WaitForSingleObject(sockets_mutex, INFINITE);
	for (int i = 0; i < sockets_len; ++i) {
		if (sockets[i].s == s) {
			socket_data = &sockets[i];
			break;
		}
	}
	ReleaseMutex(sockets_mutex);
	return socket_data;
}

bool running() {
	DWORD pid = GetProcessId(GetCurrentProcess());
	wchar_t mutex_name[MAX_PATH];
	_snwprintf(mutex_name, MAX_PATH, L"autopunch-singleton-%lu", pid);
	singleton_mutex = OpenMutexW(MUTEX_ALL_ACCESS, false, mutex_name);
	if (singleton_mutex != NULL) {
		singleton_mutex = NULL;
		CloseHandle(singleton_mutex);
		return true;
	}
	singleton_mutex = CreateMutexW(NULL, false, mutex_name);
	return false;
}

void autopunch_init() {
	if (running()) {
		log_printf("already running, quitting\n");
		return;
	}
	started = true;

	log_printf("load_start\n");

	u_long relay_ip_net = get_relay_ip();
	u_short relay_port_net = htons(relay_port);
	relay_addr = (struct sockaddr_in){.sin_family = AF_INET, .sin_port = relay_port_net, .sin_addr= {relay_ip_net}};

	sockets_mutex = CreateMutex(NULL, FALSE, NULL);
	relay_thread = CreateThread(NULL, 0, relay, NULL, 0, NULL);

	log_printf("load_end relay=%d\n",relay_thread);
}

void autopunch_cleanup() {
	log_printf("unload_start\n");

	if (started) {
		started = false;
		relay_close = true;
		ReleaseMutex(singleton_mutex);
		CloseHandle(singleton_mutex);
		WaitForSingleObject(sockets_mutex, INFINITE);
		CloseHandle(relay_thread);
		CloseHandle(sockets_mutex);
		log_printf("unload free sockets: %zu %zu %zu\n", sockets_len, sockets_cap, (size_t)sockets);
		free(sockets);
	}

	log_printf("unload_end\n");
}
