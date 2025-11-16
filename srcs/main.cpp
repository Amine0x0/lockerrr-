#include "include/locker.hpp"
#include <csignal>
#include <cstdlib>

volatile sig_atomic_t authentication_complete = 0;

void signal_handler(int sig)
{
    (void)sig;
    
    if (!authentication_complete)
    {
        std::cout << "\nAuthentication required.\n" << std::endl;
        return;
    }
    exit(0);
}

bool    start()
{
    Lock* instance = new Lock;
    
    instance->run();
    bool authenticated = instance->is_authenticated();
    
    if (authenticated)
        authentication_complete = 1;
    
    delete instance;
    return authenticated;
}

int main()
{
    signal(SIGINT, signal_handler);
    signal(SIGQUIT, signal_handler);
    signal(SIGTSTP, signal_handler);
    signal(SIGTERM, signal_handler);
    
    if (start() == true)
        return 0;
    return 1;
}
