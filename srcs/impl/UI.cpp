#include "../../include/locker.hpp"
#include <fstream>

UserInterface::UserInterface() {}

void UserInterface::print(std::string input) const
{
    if (input.empty())
        return;
    std::cout << input << std::endl;
}

void UserInterface::separator() const
{
    std::cout << "\n----------------------------------------\n" << std::endl;
}

void UserInterface::success() const
{
    std::string color = "\033[38;2;137;180;250m";
    std::string reset = "\033[0m";
    std::cout << color << "Access granted" << reset << std::endl;
}

void UserInterface::error() const
{
    std::string color = "\033[38;2;243;139;168m";
    std::string reset = "\033[0m";
    std::cout << color << "Authentication failed" << reset << std::endl;
}

void UserInterface::logo() const
{
    std::string colors[] = {
        "\033[38;2;203;166;247m",
        "\033[38;2;245;194;231m",
        "\033[38;2;148;226;213m",
        "\033[38;2;137;220;235m",
        "\033[38;2;116;199;236m",
        "\033[38;2;137;180;250m"
    };
    std::string reset = "\033[0m";
    
    std::string home = std::getenv("HOME") ? std::string(std::getenv("HOME")) : "";
    std::string filename = home + "/.locker/art";
    std::string line;
    std::fstream file(filename);

    if (!file.is_open())
    {
        filename = "art/art";
        file.open(filename);
    }

    if (!file.is_open())
        return;
    
    int line_num = 0;
    while (std::getline(file, line))
    {
        std::cout << colors[line_num % 6] << line << reset << std::endl;
        line_num++;
    }
    
    print("");
}
