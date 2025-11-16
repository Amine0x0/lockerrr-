#pragma once

#include <iostream>
#include <vector>
#include <string>
#include "json.hpp"

class UserInterface {
    private:
    public:
        void    print(std::string) const;
        void    logo() const;
        void    separator() const;
        void    success() const;
        void    error() const;

    UserInterface();
};

class Lock {
    private:
        UserInterface ui;
        std::string phrase_input;
        std::string pass_input;
        bool authenticated;
    public:
        void    run();
        void    login();
        void    setup_first_time();
        bool    check_phrase();
        void    logerr();
        bool    check_pass();
        void    grant();
        bool    is_authenticated() const;
    Lock();
};

