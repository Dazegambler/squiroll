#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0

#define starts_with(...) _Starts_with(__VA_ARGS__)
#define ends_with(...) _Starts_with(__VA_ARGS__)
#endif

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <limits.h>

#include <algorithm>
#include <utility>
#include <unordered_map>
#include <deque>
#include <queue>
#include <atomic>
#include <mutex>
#include <shared_mutex>
#include <vector>
#include <type_traits>

#include <string>
#include <string_view>
using namespace std::literals::string_literals;
using namespace std::literals::string_view_literals;

template <size_t bit_count>
using SBitIntType = std::conditional_t<bit_count <= 8, int8_t,
                    std::conditional_t<bit_count <= 16, int16_t,
                    std::conditional_t<bit_count <= 32, int32_t,
                    std::conditional_t<bit_count <= 64, int64_t,
                    void>>>>;
template <size_t bit_count>
using UBitIntType = std::conditional_t<bit_count <= 8, uint8_t,
                    std::conditional_t<bit_count <= 16, uint16_t,
                    std::conditional_t<bit_count <= 32, uint32_t,
                    std::conditional_t<bit_count <= 64, uint64_t,
                    void>>>>;

#define LOBBY_STATISTICS 0
#define LOBBY_BOT_INTEGRATION 1

#define LOBBY_IRC_LOGGING 1
#define LOBBY_UDP_LOGGING 1
#define LOBBY_BOT_LOGGING 0
#define LOBBY_DEBUG_LOGGING 0

#if LOBBY_DEBUG_LOGGING
#define debug_printf(...) printf(__VA_ARGS__)
#else
#define debug_printf(...)
#endif

#if LOBBY_IRC_LOGGING
#define irc_msg_printf(...) printf(__VA_ARGS__)
#define irc_debug_printf(...) debug_printf(__VA_ARGS__)
#else
#define irc_msg_printf(...)
#define irc_debug_printf(...)
#endif

#if LOBBY_UDP_LOGGING
#define udp_printf(...) printf(__VA_ARGS__)
#define udp_debug_printf(...) debug_printf(__VA_ARGS__)
#else
#define udp_printf(...)
#define udp_debug_printf(...)
#endif

#if LOBBY_BOT_LOGGING
#define bot_printf(...) printf(__VA_ARGS__)
#define bot_debug_printf(...) debug_printf(__VA_ARGS__)
#else
#define bot_printf(...)
#define bot_debug_printf(...)
#endif

#if _WIN32
#include <conio.h>
#include <Windows.h>
#endif

#if _WIN32
#define INCLUDE_KEYBOARD_FUNCTIONS 1
#else
typedef uint64_t LARGE_INTEGER;
#endif

#define ZNET_IPV6_MODE ZNET_DISABLE_IPV6

#include "znet.h"
#include "zthread.h"

using namespace zero::net;
using namespace zero::thread;

#include "common.h"

#include "packet_types.h"

static constexpr PacketPunchPing PUNCH_PING_PACKET = {
    .type = PACKET_TYPE_PUNCH_PING
};

enum ArgIndex {
    PROGRAM_NAME_ARG = 0,
    PORT_ARG = 1,
    MIN_REQUIRED_ARGS
};

static constexpr size_t TCP_BUFFER_SIZE = 4096;
static constexpr size_t TCP_SLEEP_TIME = 0.01_secms;
static constexpr size_t UDP_BUFFER_SIZE = 64;
static constexpr size_t UDP_SLEEP_TIME = 0.01_secms;

static constexpr size_t UDP_PORT_TIMEOUT = 0.5_secms;
static constexpr size_t UDP_PORT_ITER_DELAY = 0.01_secms;

static constexpr size_t UDP_PORT_ITERS = UDP_PORT_TIMEOUT / UDP_PORT_ITER_DELAY;

#if LOBBY_BOT_INTEGRATION
static constexpr size_t BOT_SLEEP_TIME = 5_secms;
#endif

static constexpr size_t CLIENT_SETUP_TIMEOUT = 1_secms;
static constexpr size_t JOIN_SETUP_TIMEOUT = 5_secms;
static constexpr size_t PONG_TIMEOUT = 15_secms;

static constexpr size_t PACKET_TYPE_LOBBY_NAME_MAX_SIZE = sizeof(PacketLobbyName) + MAX_NICKNAME_LENGTH;
static constexpr size_t PACKET_TYPE_PUNCH_WAIT_MAX_SIZE = sizeof(PacketPunchWait) + MAX_IP_BUFF_SIZE;
static constexpr size_t PACKET_TYPE_PUNCH_CONNECT_MAX_SIZE = sizeof(PacketPunchConnect) + MAX_IP_BUFF_SIZE * 2;
static constexpr size_t PACKET_TYPE_IPV6_TEST_MAX_SIZE = sizeof(PacketIPv6Test);

static constexpr size_t PACKET_TYPE_PUNCH_PEER_MAX_SIZE = sizeof(PacketPunchPeer) + MAX_IP_BUFF_SIZE;
static constexpr size_t PACKET_TYPE_PUNCH_PEER_IPV4_SIZE = sizeof(PacketPunchPeer) + sizeof(IP4_ADDRESS);
static constexpr size_t PACKET_TYPE_PUNCH_PEER_IPV6_SIZE = sizeof(PacketPunchPeer) + sizeof(IP6_ADDRESS);

static constexpr size_t MAX_SERVER_UDP_PACKET = (std::max)({
                                                    PACKET_TYPE_LOBBY_NAME_MAX_SIZE,
                                                    PACKET_TYPE_PUNCH_WAIT_MAX_SIZE,
                                                    PACKET_TYPE_PUNCH_CONNECT_MAX_SIZE,
                                                    PACKET_TYPE_PUNCH_PEER_MAX_SIZE,
                                                    PACKET_TYPE_IPV6_TEST_MAX_SIZE
                                                });

enum RoomType : uint8_t {
    FREE_ROOM,
    NOVICE_ROOM,
    VETERAN_ROOM,
    EU_ROOM,
    NA_ROOM,
    SA_ROOM,
    ASIA_ROOM,
    DEV_ROOM,
    ROOM_COUNT, // This must be the final enum value before INVALID_ROOM
    INVALID_ROOM = UINT8_MAX
};

static inline constexpr uint8_t NON_DEV_ROOM_COUNT = DEV_ROOM;

#if LOBBY_BOT_INTEGRATION
using room_mask_t = UBitIntType<(std::max)(std::bit_width((size_t)1 << (NON_DEV_ROOM_COUNT - 1)), (size_t)32)>;
static inline constexpr room_mask_t ALL_ROOMS_MASK = ((room_mask_t)1 << NON_DEV_ROOM_COUNT) - 1;
#endif

static std::atomic<uint32_t> USER_COUNT[ROOM_COUNT] = {};
#if LOBBY_STATISTICS
static std::atomic<uint64_t> TOTAL_LOBBY_MATCHES = { 0 };
#endif

struct UserData {
    std::atomic<bool> delete_flag = { false }; // 0x0
    RoomType room_type = INVALID_ROOM; // 0x1
    std::atomic<in_port_t> external_port = { 0 }; // 0x2
    SocketTCP socket; // 0x4
    std::string_view nickname; // 0x8
    sockaddr_any address = {}; // 0x10
    NicknameSource user_source;
#if LOBBY_BOT_INTEGRATION
    std::atomic<bool> is_waiting = { false };
#endif

    UserData(std::string_view nick, SocketTCP socket)
        : socket(socket), nickname(nick)
    {
        switch (*nick.data()) {
            case 'd':
                this->user_source = DISCORD_USERID;
                //printf("Got discord user!\n");
                break;
            default:
                this->user_source = AUTO_GENERATED_NAME;
                break;
        }
    }

    ~UserData() {
        if (void* name = (void*)this->nickname.data()) {
            free(name);
        }
        this->socket.close();
    }

    void send_message_from(std::string_view nick, RoomType room, std::string_view message) {
        if (
            this->room_type == room &&
            this->nickname != nick
        ) {
            if (!this->socket.send(message.data(), message.length())) {
                irc_debug_printf("SEND FAIL %u (%d)\n", WSAGetLastError(), this->socket.sock);
            }
        }
    }

    void send_message(RoomType room, std::string_view message) {
        if (
            this->room_type == room
        ) {
            if (!this->socket.send(message.data(), message.length())) {
                irc_debug_printf("SEND FAIL %u (%d)\n", WSAGetLastError(), this->socket.sock);
            }
        }
    }
};

static constexpr size_t PUNCH_DATA_TIMEOUT = 20_secms;
static constexpr size_t PUNCH_DATA_FULL_PING_TIMER = PUNCH_DATA_TIMEOUT / UDP_SLEEP_TIME;
static constexpr size_t PUNCH_DATA_PING_TIMER_SEND_THRESHOLD = PUNCH_DATA_FULL_PING_TIMER / 2;
static constexpr size_t PUNCH_DATA_PING_SEND_REPEATS = 5;
static constexpr size_t PUNCH_DATA_PING_SEND_INTERVAL = PUNCH_DATA_PING_TIMER_SEND_THRESHOLD / PUNCH_DATA_PING_SEND_REPEATS;

static_assert(PUNCH_DATA_FULL_PING_TIMER < UINT16_MAX);

struct PunchData {
    bool alive;
    uint16_t ping_timer;
    //ipaddr_any local_addr;
    sockaddr_any remote_addr;

    PunchData(
        //const ipaddr_any& local_addr,
        const sockaddr_any& remote_addr
    )
        : alive(true), ping_timer(PUNCH_DATA_FULL_PING_TIMER),
        //local_addr(local_addr),
        remote_addr(remote_addr)
    {}

    void reset_ping_timer() {
        this->ping_timer = PUNCH_DATA_FULL_PING_TIMER;
    }

    bool tick_ping_timer() {
        //printf("ping timer: %u\n", this->ping_timer);
        return --this->ping_timer;
    }

    bool ping_timer_send() const {
        return
            this->ping_timer <= PUNCH_DATA_PING_TIMER_SEND_THRESHOLD &&
            !(this->ping_timer % PUNCH_DATA_PING_SEND_INTERVAL);
    }
};

static std::unordered_map<std::string_view, UserData*> user_map;
static std::shared_mutex user_mutex;

static std::vector<PunchData> punch_data;

using shared_mutex_lock = std::shared_lock<std::shared_mutex>;
using unique_mutex_lock = std::unique_lock<std::shared_mutex>;
using basic_mutex_lock = std::lock_guard<std::mutex>;

template <typename L>
static inline void shared_user_data(std::string_view user, const L& lambda) {
    shared_mutex_lock lock(user_mutex);
    
    auto iter = user_map.find(user);
    if (iter != user_map.end()) {
        UserData* user_data = iter->second;
        lambda(user_data);
    }
}

template <typename L>
static inline void exclusive_user_data(std::string_view user, const L& lambda) {
    unique_mutex_lock lock(user_mutex);

    auto iter = user_map.find(user);
    if (iter != user_map.end()) {
        UserData* user_data = iter->second;
        lambda(user_data);
    }
}

template <typename L>
static inline bool shared_find_user_data(const L& lambda) {
    shared_mutex_lock lock(user_mutex);

    for (auto iter : user_map) {
        UserData* user_data = iter.second;
        if (lambda(user_data)) {
            return true;
        }
    }
    return false;
}

static inline bool insert_user_data(std::string_view user, SocketTCP socket) {
    unique_mutex_lock lock(user_mutex);

    if (!user_map.contains(user)) {
        char* user_ptr = (char*)malloc(user.length() + 1);
        user_ptr[user.length()] = '\0';
        memcpy(user_ptr, user.data(), user.length());

        std::string_view user_full{ user_ptr, user.length() };
        auto [iter, success] = user_map.try_emplace(user_full, nullptr);
        if (success) {
            //printf("New user: %s\n", user_full.data());
            iter->second = new UserData(user_full, socket);
            return true;
        }
        else {
            free(user_ptr);
        }
    }
    return false;
}

static inline void remove_user_data(std::string_view user) {
    shared_mutex_lock lock(user_mutex);

    auto iter = user_map.find(user);
    if (iter != user_map.end()) {
        iter->second->delete_flag = true;
    }
}

template<typename L>
static inline void shared_iter_user_data(const L& lambda) {
    shared_mutex_lock lock(user_mutex);

    for (auto user_data : user_map) {
        lambda(user_data.second);
    }
}

template <typename L>
static inline void exclusive_iter_user_data(const L& lambda) {
    unique_mutex_lock lock(user_mutex);

    auto user_iter = user_map.begin();
    while (user_iter != user_map.end()) {
        auto cur_iter = user_iter++;
        if (!lambda(cur_iter->second)) {
            UserData* temp = cur_iter->second;
            user_map.erase(cur_iter);
            delete temp;
        }
    }
}

static inline void insert_punch_data(
    //const ipaddr_any& local_addr,
    const sockaddr_any& remote_addr
) {
    for (auto& punch_data : punch_data) {
        if (!punch_data.alive) {
            punch_data.alive = true;
            punch_data.ping_timer = PUNCH_DATA_FULL_PING_TIMER;
            //punch_data.local_addr = local_addr;
            punch_data.remote_addr = remote_addr;
            return;
        }
    }
    punch_data.emplace_back(
        //local_addr,
        remote_addr
    );
}

template <typename L>
static inline bool find_punch_data(const L& lambda) {
    for (auto& punch_data : punch_data) {
        if (lambda(punch_data)) {
            return true;
        }
    }
    return false;
}

template <typename L>
static inline void iter_punch_data(const L& lambda) {
    for (auto& punch_data : punch_data) {
        lambda(punch_data);
    }
}

static inline constexpr char REQUEST_LOGIN_REPLY[] = "E\n";

static inline constexpr char NICK_IN_USE_REPLY[] = ": 433 E\n";
static inline constexpr char REQUEST_JOIN_REPLY[] = ": 422 E\n";

#if LOBBY_BOT_INTEGRATION
static inline constexpr std::string_view ROOM_JSON_STARTS[] = {
    "\"Free\":["sv,
    "\"Novice\":["sv,
    "\"Veteran\":["sv,
    "\"EU\":["sv,
    "\"NA\":["sv,
    "\"SA\":["sv,
    "\"Asia\":["sv
};

static inline constexpr size_t BOT_MESSAGE_BASE_LENGTH = sizeof(":LOBBY PRIVMSG bot :{\"Free\":[],\"Novice\":[],\"Veteran\":[],\"EU\":[],\"NA\":[],\"SA\":[],\"Asia\":[]}") + 1;
static inline constexpr std::string_view BOT_MESSAGE_PREFIX = ":LOBBY PRIVMSG bot :{"sv;
#endif

static inline constexpr char JOIN_FREE_REPLY[] = "! JOIN #th155_Free %u\n";
static inline constexpr char JOIN_NOVICE_REPLY[] = "! JOIN #th155_Novice %u\n";
static inline constexpr char JOIN_VETERAN_REPLY[] = "! JOIN #th155_Veteran %u\n";
static inline constexpr char JOIN_EU_REPLY[] = "! JOIN #th155_EU %u\n";
static inline constexpr char JOIN_NA_REPLY[] = "! JOIN #th155_NA %u\n";
static inline constexpr char JOIN_SA_REPLY[] = "! JOIN #th155_SA %u\n";
static inline constexpr char JOIN_ASIA_REPLY[] = "! JOIN #th155_Asia %u\n";
static inline constexpr char JOIN_DEV_REPLY[] = "! JOIN #th155_Dev %u\n";

static inline constexpr std::string_view JOIN_FREE_VIEW = "JOIN #th155_Free Free"sv;
static inline constexpr std::string_view JOIN_NOVICE_VIEW = "JOIN #th155_Novice Novice"sv;
static inline constexpr std::string_view JOIN_VETERAN_VIEW = "JOIN #th155_Veteran Veteran"sv;
static inline constexpr std::string_view JOIN_EU_VIEW = "JOIN #th155_EU EU"sv;
static inline constexpr std::string_view JOIN_NA_VIEW = "JOIN #th155_NA NA"sv;
static inline constexpr std::string_view JOIN_SA_VIEW = "JOIN #th155_SA SA"sv;
static inline constexpr std::string_view JOIN_ASIA_VIEW = "JOIN #th155_Asia Asia"sv;
static inline constexpr std::string_view JOIN_DEV_VIEW = "JOIN #th155_Dev Dev"sv;

#define CALC_JOIN_USERS_BUFFER(max_val) sizeof("! JOIN #th155_Veteran " MACRO_STR(max_val) "\n")

static inline constexpr size_t JOIN_AND_USER_COUNT_BUFFER_SIZE = CALC_JOIN_USERS_BUFFER(4294967295);

static inline constexpr char USER_COUNT_REPLY[] = "USERS ";
static inline constexpr size_t USER_COUNT_REPLY_LEN = sizeof(USER_COUNT_REPLY) - 1;

static inline constexpr char PING_MESSAGE[] = "PING\n";
static inline constexpr std::string_view PONG_REPLY = "PONG 0"sv;

static inline constexpr char ERROR_MESSAGE[] = "ERROR\n";

static inline constexpr std::string_view STAT_COMMAND_VIEW = "STAT"sv;
static inline constexpr std::string_view REQUEST_MATCH_COMMAND_VIEW = "REQUEST_MATCH "sv;
static inline constexpr std::string_view WELCOME_COMMAND_VIEW = "WELCOME "sv;

static inline constexpr std::string_view PASSWORD_VIEW = "kzxmckfqbpqieh8rw<rczuturKfnsjxhauhybttboiuuzmWdmnt5mnlczpythaxf"sv;

#if LOBBY_BOT_INTEGRATION
static inline constexpr std::string_view BOT_PASSWORD_VIEW = "bot_test"sv;

static std::atomic<room_mask_t> room_update_mask = {};
static std::vector<SocketTCP> bot_vector;
static std::mutex bot_mutex;
static char* bot_messages[NON_DEV_ROOM_COUNT] = {};
static size_t bot_message_lengths[NON_DEV_ROOM_COUNT] = {};
static size_t bot_message_buffers[NON_DEV_ROOM_COUNT] = {};

static void build_bot_messages(room_mask_t rooms) {

    for (size_t i = 0; i < NON_DEV_ROOM_COUNT; ++i) {
        bot_message_lengths[i] = 0;
    }

    shared_iter_user_data([=](UserData* user_data) {
        if (user_data->is_waiting) {
            RoomType user_room = user_data->room_type;
            if (rooms & 1 << user_room) {
                size_t nickname_length = user_data->nickname.length();
                size_t prev_length = bot_message_lengths[user_room];
                size_t total_filled = prev_length + nickname_length + 3;
                bot_message_lengths[user_room] = total_filled;
                if (total_filled > bot_message_buffers[user_room]) {
                    bot_message_buffers[user_room] = total_filled;
                    bot_messages[user_room] = (char*)realloc(bot_messages[user_room], total_filled);
                }
                char* message_ptr = bot_messages[user_room] + prev_length;
                *message_ptr++ = '"';
                memcpy(message_ptr, user_data->nickname.data(), nickname_length);
                message_ptr[nickname_length] = '"';
                message_ptr[nickname_length + 1] = ',';
            }
        }
    });
}

static bool add_bot_sock(SocketTCP socket) {
    basic_mutex_lock lock(bot_mutex);

    build_bot_messages(ALL_ROOMS_MASK);

    size_t total_length = BOT_MESSAGE_BASE_LENGTH;
    for (size_t i = 0; i < NON_DEV_ROOM_COUNT; ++i) {
        if (size_t room_length = bot_message_lengths[i]) {
            total_length += room_length - 1; // Get rid of any trailing commas
        }
    }

    char full_bot_message[total_length];
    memcpy(full_bot_message, BOT_MESSAGE_PREFIX.data(), BOT_MESSAGE_PREFIX.length());
    size_t write_offset = BOT_MESSAGE_PREFIX.length();

    for (size_t i = 0; i < NON_DEV_ROOM_COUNT; ++i) {
        size_t json_start_len = ROOM_JSON_STARTS[i].length();
        memcpy(&full_bot_message[write_offset], ROOM_JSON_STARTS[i].data(), json_start_len);
        write_offset += json_start_len;
        if (size_t room_length = bot_message_lengths[i]) {
            --room_length; // Get rid of any trailing commas
            memcpy(&full_bot_message[write_offset], bot_messages[i], room_length);
            write_offset += room_length;
        }
        full_bot_message[write_offset++] = ']';
        full_bot_message[write_offset++] = ',';
    }

    // There will always be a comma at this position because all rooms are iterated
    full_bot_message[write_offset - 1] = '}';

    full_bot_message[write_offset++] = '\r';
    full_bot_message[write_offset++] = '\n';

    bot_debug_printf("BOTA:%.*s", (int)write_offset, full_bot_message);

    if (socket.send(full_bot_message, write_offset)) {
        bot_vector.push_back(socket);
        return true;
    }
    return false;
}

static void update_bots(room_mask_t rooms) {
    basic_mutex_lock lock(bot_mutex);
    if (!bot_vector.empty()) {
        build_bot_messages(rooms);

        size_t total_length = BOT_MESSAGE_BASE_LENGTH;
        for (size_t i = 0; i < NON_DEV_ROOM_COUNT; ++i) {
            if (rooms & 1 << i) {
                if (size_t room_length = bot_message_lengths[i]) {
                    total_length += room_length - 1; // Get rid of any trailing commas
                }
            }
        }

        char full_bot_message[total_length];
        memcpy(full_bot_message, BOT_MESSAGE_PREFIX.data(), BOT_MESSAGE_PREFIX.length());
        size_t write_offset = BOT_MESSAGE_PREFIX.length();

        for (size_t i = 0; i < NON_DEV_ROOM_COUNT; ++i) {
            if (rooms & 1 << i) {
                size_t json_start_len = ROOM_JSON_STARTS[i].length();
                memcpy(&full_bot_message[write_offset], ROOM_JSON_STARTS[i].data(), json_start_len);
                write_offset += json_start_len;
                if (size_t room_length = bot_message_lengths[i]) {
                    --room_length; // Get rid of any trailing commas
                    memcpy(&full_bot_message[write_offset], bot_messages[i], room_length);
                    write_offset += room_length;
                }
                full_bot_message[write_offset++] = ']';
                full_bot_message[write_offset++] = ',';
            }
        }

        // There will always be a comma at this position because this
        // function is only called when the room mask is non-zero
        full_bot_message[write_offset - 1] = '}';

        full_bot_message[write_offset++] = '\r';
        full_bot_message[write_offset++] = '\n';

        bot_debug_printf("BOTU:%.*s", (int)write_offset, full_bot_message);

        size_t i = 0;
        do {
            SocketTCP socket = bot_vector[i];
            if (!socket.send(full_bot_message, write_offset)) {
                // Based on a quick test, this code does run
                bot_debug_printf("Closing bot socket\n");
                socket.close();
                bot_vector.erase(bot_vector.begin() + i);
                continue;
            }
            ++i;
        } while (i < bot_vector.size());
    }
}

#endif

enum UserCountModType {
    INC_USER_COUNT,
    DEC_USER_COUNT
};

template<UserCountModType type>
static void send_user_count_packet(char* buffer, RoomType room_type) {
#if LOBBY_BOT_INTEGRATION
    if (room_type != DEV_ROOM) {
        (void)room_update_mask.fetch_or((room_mask_t)1 << room_type);
    }
#endif
    size_t user_count_len;
    if constexpr (type == INC_USER_COUNT) {
        user_count_len = sprintf(&buffer[USER_COUNT_REPLY_LEN], "%u\n", ++USER_COUNT[room_type]) + USER_COUNT_REPLY_LEN;
    }
    else if constexpr (type == DEC_USER_COUNT) {
        user_count_len = sprintf(&buffer[USER_COUNT_REPLY_LEN], "%u\n", --USER_COUNT[room_type]) + USER_COUNT_REPLY_LEN;
    }
    std::string_view user_count_view{ buffer, user_count_len };
    irc_msg_printf("SEND:%.*s", (int)user_count_view.length(), user_count_view.data());
    shared_iter_user_data([=](UserData* user_data) {
        user_data->send_message(room_type, user_count_view);
    });
}

int main(int argc, char* argv[]) {
    if (argc < MIN_REQUIRED_ARGS) {
        error_exit("aocf_server.exe <port>");
    }

    uint16_t port;
    if (!strbuf_to_uint16(argv[PORT_ARG], port)) {
        error_exit("Invalid port");
    }

    if (!enable_winsock()) {
        error_exit("Count not initialize winsock");
    }

    if (SocketTCP tcp_socket = SocketTCP::create()) {
        if (tcp_socket.bind(port)) {
            if (SocketUDP udp_socket = SocketUDP::create()) {
                if (udp_socket.bind(port)) {

                    tcp_socket.set_blocking_state(false);

                    tcp_socket.listen(50);

#if INCLUDE_KEYBOARD_FUNCTIONS
                    zjthread stupid_keyboard_thread([](const std::atomic<uint8_t>& stop) {
                        wait_for_keyboard(1_secms);
                    });
#endif
#if LOBBY_BOT_INTEGRATION
                    zjthread bot_thread([](const std::atomic<uint8_t>& stop) {
                        do {
                            room_mask_t mask = room_update_mask.exchange(0);
                            if (mask) {
                                update_bots(mask);
                            }
                            wait_milliseconds(BOT_SLEEP_TIME);
                        } while (!stop);
                    });
#endif

                    udp_socket.set_blocking_state(false);
                    //udp_socket.set_receive_timeout(UDP_SLEEP_TIME);

                    zjthread udp_listen_thread([=](const std::atomic<uint8_t>& stop) {
                        do {
                            unsigned char buffer[MAX_SERVER_UDP_PACKET];

                            sockaddr_any peer_addr;
                            if (size_t receive_length = udp_socket.receive(buffer, peer_addr)) {

                                PacketLayout* raw_packet = (PacketLayout*)buffer;
                                udp_debug_printf("UDP: %zu type %hhu\n", receive_length, raw_packet->type);
                                switch (raw_packet->type) {
                                    case PACKET_TYPE_LOBBY_NAME: case PACKET_TYPE_LOBBY_NAME_WAIT: {

                                        PacketLobbyName* packet = (PacketLobbyName*)raw_packet;

                                        in_port_t peer_port = get_port(peer_addr);

#if LOBBY_UDP_LOGGING && LOBBY_DEBUG_LOGGING
                                        printf("NAMEPORT: %.*s = %u ", (int)packet->length, packet->name, peer_port);
                                        print_sockaddr(peer_addr);
                                        printf("\n");
#endif

                                        std::string_view peer_nickname_view{ packet->name, packet->length };

                                        shared_user_data(peer_nickname_view, [=](UserData* user_data) {
                                            user_data->external_port = peer_port;
                                            //user_data->user_source = packet->source;
                                        });
                                        if (raw_packet->type != PACKET_TYPE_LOBBY_NAME_WAIT) {
                                            goto skip_punch_wait;
                                        }
                                    }
                                    case PACKET_TYPE_PUNCH_WAIT: {
                                        //PacketPunchWait* packet = (PacketPunchWait*)raw_packet;
                                        insert_punch_data(
                                            //packet->local_ip(), 
                                            peer_addr
                                        );
                                    }
                                    skip_punch_wait: {
                                        new (buffer) PacketPunchSelf(peer_addr);
                                        udp_socket.send(buffer, sizeof(PacketPunchSelf), peer_addr);
                                        break;
                                    }
                                    case PACKET_TYPE_PUNCH_PING: {
#if LOBBY_UDP_LOGGING && LOBBY_DEBUG_LOGGING
                                        printf("PUNCH PING ");
                                        print_sockaddr(peer_addr);
                                        printf("\n");
#endif
                                        find_punch_data([&](PunchData& punch_data) {
                                            if (
                                                punch_data.alive &&
                                                ports_match(punch_data.remote_addr, peer_addr) &&
                                                ips_match(punch_data.remote_addr, peer_addr)
                                            ) {
                                                punch_data.reset_ping_timer();
                                                return true;
                                            }
                                            return false;
                                        });
                                        break;
                                    }
                                    case PACKET_TYPE_PUNCH_CONNECT: {
                                        PacketPunchConnect* packet = (PacketPunchConnect*)raw_packet;
                                        ipaddr_any dest_addr = packet->dest_ip();
                                        find_punch_data([&](PunchData& punch_data) {
                                            if (
                                                punch_data.alive &&
                                                //ports_match(punch_data.local_addr, dest_addr) &&
                                                ports_match(punch_data.remote_addr, dest_addr) &&
                                                ips_match(punch_data.remote_addr, dest_addr)
                                            ) {
                                                //PacketPunchPeer packet;

                                                // TODO: Attempt to map between v4 and v6 for compatibility

                                                new (buffer) PacketPunchPeer(peer_addr);
                                                udp_socket.send(buffer, sizeof(PacketPunchPeer), punch_data.remote_addr);
                                                //new (buffer) PacketPunchPeer(punch_data.remote_addr);
                                                //udp_socket.send(buffer, sizeof(PacketPunchPeer), peer_addr);
                                                return true;
                                            }
                                            return false;
                                        });
                                        break;
                                    }
                                    case PACKET_TYPE_IPV6_TEST: {
                                        //printf("IPv6 test received\n");
                                        udp_socket.send(*(PacketIPv6Test*)buffer, peer_addr);
                                        break;
                                    }
                                    case PACKET_TYPE_PUNCH_DELAY_PING: {
                                        PacketPunchDelayPing* packet = (PacketPunchDelayPing*)raw_packet;
                                        ipaddr_any dest_addr = packet->dest_ip();
                                        packet->flags &= 0x7F;
                                        packet->flags |= peer_addr.storage.ss_family == AF_INET6 ? 0x80 : 0x00;
                                        packet->dest_port = get_port(peer_addr);
                                        memset(packet->dest_ip_buf, 0, sizeof(packet->dest_ip_buf));
                                        peer_addr.store_ip(packet->dest_ip_buf);
                                        find_punch_data([&](PunchData& punch_data) {
                                            if (
                                                punch_data.alive &&
                                                //ports_match(punch_data.local_addr, dest_addr) &&
                                                ports_match(punch_data.remote_addr, dest_addr) &&
                                                ips_match(punch_data.remote_addr, dest_addr)
                                            ) {
                                                udp_socket.send(packet, sizeof(PacketPunchDelayPing), punch_data.remote_addr);
                                                return true;
                                            }
                                            return false;
                                        });
                                        break;
                                    }
                                    case PACKET_TYPE_PUNCH_DELAY_PONGA: {
                                        PacketPunchDelayPing* packet = (PacketPunchDelayPing*)raw_packet;
                                        sockaddr_any dest_addr = packet->dest_sock();
                                        packet->type = PACKET_TYPE_PUNCH_DELAY_PONGB;
                                        packet->flags &= 0x7F;
                                        udp_socket.send(packet, sizeof(PacketPunchDelayPong), dest_addr);
                                        break;
                                    }
                                }
                            }
                            iter_punch_data([&](PunchData& punch_data) {
                                if (punch_data.alive) {
                                    if (punch_data.tick_ping_timer()) {
                                        if (punch_data.ping_timer_send()) {
                                            //printf("Sending punch ping...\n");
                                            udp_socket.send(PUNCH_PING_PACKET, punch_data.remote_addr);
                                        }
                                    }
                                    else {
                                        udp_debug_printf("Killed punch client\n");
                                        punch_data.alive = false;
                                    }
                                }
                            });
                            wait_milliseconds(UDP_SLEEP_TIME);
                        } while (!stop);
                        printf(
                            "!!!!! UDP THREAD EXIT !!!!!\n"
#if LOBBY_STATISTICS
                            "!!!!! TOTAL MATCHES: %llu\n", TOTAL_LOBBY_MATCHES.load()
#endif
                        );
                    });

                    do {
                        if (SocketTCP response_socket = tcp_socket.accept()) {
                            irc_debug_printf("Accepted connection!\n");
                            std::thread([response_socket]() mutable {

                                response_socket.set_blocking_state(true);

                                response_socket.set_receive_timeout(CLIENT_SETUP_TIMEOUT);
                                response_socket.send_text(REQUEST_LOGIN_REPLY);

                                char text[TCP_BUFFER_SIZE];
                                std::queue<std::string_view> messages;

                                char name_buffer[MAX_NICKNAME_LENGTH + 1 + std::max((size_t)32, MAX_ADDR_BUFF_SIZE)]{ ':' };
                        
                                auto receive_message = [&, response_socket](std::string_view& out) -> bool {
                            
                                    if (messages.empty()) {
                                        if (size_t length = response_socket.receive_text(text)) {
                                            ++length;
                                            char* text_start = text;
                                            char* text_read = text;
                                            do {
                                                char c = *text_read;
                                                switch (c) {
                                                    case '\r': case '\n':
                                                        *text_read = '\0';
                                                    case '\0':
                                                        if (size_t message_length = text_read - text_start) {
                                                            //printf("MSG :%s\n", text_start);
                                                            messages.emplace(text_start, message_length);
                                                        }
                                                        text_start = text_read + 1;
                                                }
                                                ++text_read;
                                            } while (--length);
                                            if (messages.empty()) {
                                                return false;
                                            }
                                        }
                                        else {
                                            return false;
                                        }
                                    }
                                    out = messages.front();
                                    //printf("GOT :%s\n", out.data());
                                    messages.pop();
                                    return true;
                                };

                                std::string_view message_view;
                                std::string_view nick_view = {};
                                uint8_t login_bits = 0;
                                for (; login_bits < 0b11000000; login_bits += 0b01000000) {
                                    if (receive_message(message_view)) {
                                        if (message_view.starts_with("NICK "sv)) {
                                            if (!(login_bits & 0b00000001)) {
                                                login_bits |= 0b00000001;
                                                //printf("%s\n", message_view.data());
                                                memcpy(name_buffer + 1, message_view.data() + 5, message_view.length() - 4);
                                                nick_view = { name_buffer + 1, message_view.length() - 5 };
                                                continue;
                                            }
                                        }
                                        else if (message_view.starts_with("PASS "sv)) {
                                            if (!(login_bits & 0b00000010)) {
                                                login_bits |= 0b00000010;
                                                //printf("%s\n", message_view.data());
                                                message_view.remove_prefix(5);
                                                if (message_view == PASSWORD_VIEW) {
                                                    continue;
                                                }
#if LOBBY_BOT_INTEGRATION
                                                else if (message_view == BOT_PASSWORD_VIEW) {
                                                    login_bits |= 0b00001000;
                                                    continue;
                                                }
#endif
                                            }
                                        }
                                        else if (message_view.starts_with("USER "sv)) {
                                            if (!(login_bits & 0b00000100)) {
                                                login_bits |= 0b00000100;
                                                // Even though IRC usernames are meant to be how a server identifies you,
                                                // the client just sends the nickname again for this field. There's nothing
                                                // really useful to do with it because the clients later use nickname for
                                                // everything important.
                                                //printf("%s\n", message_view.data());
                                                continue;
                                            }
                                        }
                                    }
                                    goto disconnect;
                                }

                                // It *should* be impossible to reach here without
                                // having received the full NICK/PASS/USER combo.
#if LOBBY_BOT_INTEGRATION
                                if (expect(login_bits & 0b00001000, false)) {
                                    if (
                                        nick_view != "bot"sv ||
                                        !add_bot_sock(response_socket)
                                    ) {
                                        response_socket.close();
                                    }
                                    return;
                                }
#endif

                                for (;;) {
                                    //printf("NICK:%.*s\n", (int)nick_view.length(), nick_view.data());
                                    if (!insert_user_data(nick_view, response_socket)) {
                                        response_socket.send_text(NICK_IN_USE_REPLY);

                                        if (receive_message(message_view) && message_view.starts_with("NICK "sv)) {
                                            memcpy(name_buffer + 1, message_view.data() + 5, message_view.length() - 4);
                                            nick_view = { name_buffer + 1, message_view.length() - 5 };
                                            //printf("%s", textA);
                                            continue;
                                        }
                                        goto disconnect;
                                    }
                                    break;
                                }
                                
                                response_socket.send_text(REQUEST_JOIN_REPLY);

                                response_socket.set_receive_timeout(JOIN_SETUP_TIMEOUT);

                                if (receive_message(message_view)) {
                                    //printf("%s\n", message_view.data());

                                    RoomType room_type;

                                    const char* join_response_str;
                                    char join_and_users_buffer[JOIN_AND_USER_COUNT_BUFFER_SIZE];
                                    size_t join_response_length;
                                    if (message_view == JOIN_FREE_VIEW) {
                                        join_response_str = JOIN_FREE_REPLY;
                                        room_type = FREE_ROOM;
                                    }
                                    else if (message_view == JOIN_NOVICE_VIEW) {
                                        join_response_str = JOIN_NOVICE_REPLY;
                                        room_type = NOVICE_ROOM;
                                    }
                                    else if (message_view == JOIN_VETERAN_VIEW) {
                                        join_response_str = JOIN_VETERAN_REPLY;
                                        room_type = VETERAN_ROOM;
                                    }
                                    else if (message_view == JOIN_EU_VIEW) {
                                        join_response_str = JOIN_EU_REPLY;
                                        room_type = EU_ROOM;
                                    }
                                    else if (message_view == JOIN_NA_VIEW) {
                                        join_response_str = JOIN_NA_REPLY;
                                        room_type = NA_ROOM;
                                    }
                                    else if (message_view == JOIN_SA_VIEW) {
                                        join_response_str = JOIN_SA_REPLY;
                                        room_type = SA_ROOM;
                                    }
                                    else if (message_view == JOIN_ASIA_VIEW) {
                                        join_response_str = JOIN_ASIA_REPLY;
                                        room_type = ASIA_ROOM;
                                    }
                                    else if (message_view == JOIN_DEV_VIEW) {
                                        join_response_str = JOIN_DEV_REPLY;
                                        room_type = DEV_ROOM;
                                    }
                                    else {
                                        remove_user_data(nick_view);
                                        goto disconnect;
                                    }

                                    join_response_length = sprintf(join_and_users_buffer, join_response_str, USER_COUNT[room_type].load());

                                    sockaddr_any address;
                                    response_socket.get_peer_addr(address);

                                    shared_user_data(nick_view, [&](UserData* user_data) {
                                        user_data->room_type = room_type;
                                        user_data->address = address;
                                    });

                                    memcpy(name_buffer + 1 + nick_view.length(), join_and_users_buffer, JOIN_AND_USER_COUNT_BUFFER_SIZE);

                                    //printf("%s", name_buffer);
                                    response_socket.send(name_buffer, 1 + nick_view.length() + join_response_length);

                                    name_buffer[1 + nick_view.length() + 0] = '!';
                                    name_buffer[1 + nick_view.length() + 1] = '@';

                                    response_socket.set_receive_timeout(PONG_TIMEOUT);

                                    char* ip_buffer = name_buffer + 1 + nick_view.length() + 2;
                                    ip_buffer[sprint_sockaddr(address, ip_buffer)] = '\0';
                                    //printf("NAME:%s", name_buffer);
                                    std::string_view user_view{ name_buffer };
#if !LOBBY_BOT_INTEGRATION
                                    bool is_waiting = false;
#endif
                                    memcpy(join_and_users_buffer, USER_COUNT_REPLY, USER_COUNT_REPLY_LEN);
                                    do {
                                        while (receive_message(message_view)) {
                                            irc_msg_printf(
                                                "GOT :%s\n"
                                                "FROM:%s\n"
                                                , message_view.data()
                                                , nick_view.data()
                                            );

                                            char replacement_message[message_view.length() + 32];

                                            if (message_view.starts_with("PRIVMSG "sv)) {
                                                if (const char* command_start = (const char*)memchr(message_view.data(), ':', message_view.length())) {
                                                    ++command_start;

                                                    size_t prefix_length = command_start - message_view.data();
                                                    std::string_view command_view{ command_start, message_view.length() - prefix_length };

                                                    auto make_replacement_command = [&]<typename L>(const L& lambda) {
                                                        if (const char* nickname_end = (const char*)memchr(command_view.data(), ' ', command_view.length())) {
                                                            prefix_length += nickname_end - command_view.data() + 1;
                                                            for (size_t i = 0; i < UDP_PORT_ITERS; ++i) {
                                                                wait_milliseconds(UDP_PORT_ITER_DELAY);
                                                                uint16_t external_port = 0;
                                                                shared_user_data(nick_view, [&](UserData* user_data) {
                                                                    external_port = user_data->external_port;
                                                                });
                                                                if (external_port != 0) {
                                                                    lambda(external_port, prefix_length);
                                                                    break;
                                                                }
                                                            }
                                                        }
                                                    };

                                                    if (command_view.starts_with(STAT_COMMAND_VIEW)) {
#if !LOBBY_BOT_INTEGRATION
                                                        if (!is_waiting) {
                                                            send_user_count_packet<INC_USER_COUNT>(join_and_users_buffer, room_type);
                                                        }
                                                        is_waiting = true;
#else
                                                        shared_user_data(nick_view, [&, room_type](UserData* user_data) {
                                                            bool expected = false;
                                                            if (user_data->is_waiting.compare_exchange_strong(expected, true)) {
                                                                send_user_count_packet<INC_USER_COUNT>(join_and_users_buffer, room_type);
                                                            }
                                                        });
#endif
                                                    }
                                                    else if (command_view.starts_with(REQUEST_MATCH_COMMAND_VIEW)) {
                                                        prefix_length += REQUEST_MATCH_COMMAND_VIEW.length();
                                                        command_view.remove_prefix(REQUEST_MATCH_COMMAND_VIEW.length());
                                                        //printf("REPA:%s\n", command_view.data());

                                                        make_replacement_command([&](uint16_t external_port, size_t copy_length) {
                                                            int replacement_length = sprintf(replacement_message,
                                                                "%.*s%u"
                                                                , (int)copy_length, message_view.data()
                                                                , external_port
                                                            );
                                                            message_view = std::string_view(replacement_message, replacement_length);
                                                            //printf("REPB:%s\n", replacement_message);
                                                        });
                                                    }
                                                    else if (command_view.starts_with(WELCOME_COMMAND_VIEW)) {
#if LOBBY_STATISTICS
                                                        printf("!!!!! TOTAL MATCHES: %llu\n", ++TOTAL_LOBBY_MATCHES);
#endif
#if !LOBBY_BOT_INTEGRATION
                                                        if (is_waiting) {
                                                            send_user_count_packet<DEC_USER_COUNT>(join_and_users_buffer, room_type);
                                                        }
                                                        is_waiting = false;
#else
                                                        shared_user_data(nick_view, [&, room_type](UserData* user_data) {
                                                            bool expected = true;
                                                            if (user_data->is_waiting.compare_exchange_strong(expected, false)) {
                                                                send_user_count_packet<DEC_USER_COUNT>(join_and_users_buffer, room_type);
                                                            }
                                                        });
#endif

                                                        prefix_length += WELCOME_COMMAND_VIEW.length();
                                                        command_view.remove_prefix(WELCOME_COMMAND_VIEW.length());
                                                        //printf("REPC:%s\n", command_view.data());

                                                        make_replacement_command([&](uint16_t external_port, size_t copy_length) {
                                                            int replacement_length = sprintf(replacement_message,
                                                                "%.*s%u %u"
                                                                , (int)copy_length, message_view.data()
                                                                , external_port, external_port
                                                            );
                                                            message_view = std::string_view(replacement_message, replacement_length);
                                                            //printf("REPD:%s\n", replacement_message);
                                                        });
                                                    }
                                                }
                                            }

                                            {
                                                char message_buf[user_view.length() + 1 + message_view.length() + 2];
                                                int send_length = sprintf(message_buf,
                                                    "%s %s\n",
                                                    user_view.data(), message_view.data()
                                                );
                                                message_view = std::string_view(message_buf, send_length);
                                                irc_msg_printf("SEND:%.*s", (int)message_view.length(), message_view.data());
                                                shared_iter_user_data([=](UserData* user_data) {
                                                    user_data->send_message_from(nick_view, room_type, message_view);
                                                });
                                            }
                                        }
                                        response_socket.send_text(PING_MESSAGE);

                                        // If a ping needs to be sent, assume the user has stopped waiting
#if !LOBBY_BOT_INTEGRATION
                                        if (is_waiting) {
                                            send_user_count_packet<DEC_USER_COUNT>(join_and_users_buffer, room_type);
                                        }
                                        is_waiting = false;
#else
                                        shared_user_data(nick_view, [&, room_type](UserData* user_data) {
                                            bool expected = true;
                                            if (user_data->is_waiting.compare_exchange_strong(expected, false)) {
                                                send_user_count_packet<DEC_USER_COUNT>(join_and_users_buffer, room_type);
                                            }
                                        });
#endif
                                    } while (receive_message(message_view) && message_view == PONG_REPLY);

                                    irc_debug_printf("SUCCEEDED, disconnecting...\n");
                                }
                                remove_user_data(nick_view);
                                goto success;
                            disconnect:
                                irc_debug_printf("FAILED, disconnecting...\n");
                            success:
                                response_socket.close();
                            }).detach();
                        }
                        wait_milliseconds(TCP_SLEEP_TIME);
                        exclusive_iter_user_data([](UserData* user_data) -> bool {
                            return !user_data->delete_flag.load(std::memory_order_relaxed);
                        });
                    } while (
#if INCLUDE_KEYBOARD_FUNCTIONS
                        !stupid_keyboard_thread.stopped()
#else
                        true
#endif
                    );
                    udp_listen_thread.stop();
#if LOBBY_BOT_INTEGRATION
                    bot_thread.stop();
#endif
                }
                udp_socket.close();
            }
        }
        tcp_socket.close();
    }

    disable_winsock();

    return EXIT_SUCCESS;
}
