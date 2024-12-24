#pragma once

#ifndef ZTHREAD_H
#define ZTHREAD_H 1

#include <stdlib.h>
#include <stdint.h>

#include <utility>
#include <thread>
#include <atomic>

namespace zero {

namespace thread {

struct zthread : std::thread {

    using std::thread::thread;

    inline ~zthread() {
        if (this->joinable()) {
            this->join();
        }
    }
};

struct zjthread_base {
    std::atomic<uint8_t> stop_state;
};

struct zjthread : zjthread_base, std::thread {

    zjthread() noexcept : zjthread_base{{(uint8_t)~0}}, std::thread() {}

    template <typename F, typename ... Args>
    explicit zjthread(F&& f, Args&&... args) : zjthread_base{0},
        std::thread([](F&& f, std::atomic<uint8_t>* stop, Args&&... args) {
            f((const std::atomic<uint8_t>&)*stop, std::forward<Args>(args)...);
            *stop = -1;
        }, std::forward<F>(f), &this->stop_state, std::forward<Args>(args)...) {}

    inline void join() {
        this->stop_state = 1;
        return this->std::thread::join();
    }

    inline ~zjthread() {
        if (this->joinable()) {
            this->join();
        }
    }

    inline void stop() {
        return this->join();
    }

    inline bool stopped() {
        return this->stop_state == (uint8_t)~0;
    }
};

}

}

#endif