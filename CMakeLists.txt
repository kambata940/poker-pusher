cmake_minimum_required(VERSION 2.6)
project(poker_pusher)

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11" )

add_executable(poker_pusher src/main.cpp src/client_server.cpp)

target_link_libraries(poker_pusher uWS)
target_link_libraries(poker_pusher z)
target_link_libraries(poker_pusher ssl)

#target_link_libraries(poker_pusher cpp_redis)
#target_link_libraries(poker_pusher tacopie)
#target_link_libraries(poker_pusher pthread)
