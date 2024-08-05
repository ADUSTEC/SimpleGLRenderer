#pragma once
#include <chrono>

// deals with time and all that

namespace SGLR {

    class Clock {
        public:
            Clock() : m_start(std::chrono::high_resolution_clock::now()) {}

            void restart() 
            {
                m_start = std::chrono::high_resolution_clock::now();
            }

            const float elapsed() 
            {
                auto now = std::chrono::high_resolution_clock::now();
                return std::chrono::duration_cast<std::chrono::duration<float>>(now - m_start).count();
            }

        private:
            std::chrono::high_resolution_clock::time_point m_start;
    };
}