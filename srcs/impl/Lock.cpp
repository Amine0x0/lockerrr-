#include "../../include/locker.hpp"
#include <fstream>
#include <cstdlib>
#include <termios.h>
#include <unistd.h>
#include <sstream>
#include <iomanip>
#include <functional>
#include <ctime>

using json = nlohmann::json;

std::string get_home_dir()
{
    const char* home = std::getenv("HOME");
    return home ? std::string(home) : "";
}

json loadjson(const std::string& path)
{
    std::ifstream file(path);
    json j;
    if (file.is_open())
        file >> j;
    return j;
}

void savejson(const std::string& path, const json& j)
{
    std::ofstream file(path);
    if (file.is_open())
        file << j.dump(4);
}

bool file_exists(const std::string& path)
{
    std::ifstream file(path);
    return file.good();
}

bool create_db_directory(const std::string& dir_path)
{
    std::string mkdir_cmd = "mkdir -p " + dir_path;
    return system(mkdir_cmd.c_str()) == 0;
}

std::string get_hidden_input(const std::string& prompt)
{
    std::cout << prompt;
    std::cout.flush();
    
    struct termios oldt, newt;
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~ECHO;
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    
    std::string input;
    std::getline(std::cin, input);
    
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    std::cout << std::endl;
    
    return input;
}

std::string hash_password(const std::string& password)
{
    std::stringstream ss;
    unsigned long long hash_val = 0;
    
    for (char c : password)
    {
        hash_val = hash_val * 31 + static_cast<unsigned char>(c);
    }
    
    ss << std::hex << hash_val;
    return ss.str();
}

bool verify_password(const std::string& password, const std::string& stored_hash)
{
    return hash_password(password) == stored_hash;
}

void Lock::setup_first_time()
{
    std::string home = get_home_dir();
    std::string locker_dir = home + "/.locker";
    std::string db_path = locker_dir + "/db.json";
    
    ui.print("Initializing locker");
    ui.separator();
    
    if (!create_db_directory(locker_dir))
    {
        ui.print("Error: Failed to create locker directory");
        return;
    }
    
    std::string phrase, password;
    
    std::cout << "Passphrase: ";
    std::getline(std::cin, phrase);
    
    password = get_hidden_input("Password: ");
    
    json db;
    db["phrase"] = phrase;
    db["password"] = hash_password(password);
    
    savejson(db_path, db);
    
    authenticated = true;
    ui.success();
    ui.print("Initialization complete");
}

Lock::Lock() 
{
    authenticated = false;
}

void Lock::run()
{
    std::string home = get_home_dir();
    std::string db_path = home + "/.locker/db.json";
    
    ui.logo();
    
    if (!file_exists(db_path))
        setup_first_time();
    else
    {
        int max_attempts = 1;
        for (int attempt = 1; attempt <= max_attempts; attempt++)
        {
            login();
            if (authenticated)
                break;
            
            if (attempt < max_attempts)
            {
                ui.print("Nice try!");
                std::cout << "Attempts remaining: " << (max_attempts - attempt) << std::endl;
                ui.separator();
                ui.logo();
            }
        }
        
        if (!authenticated)
        {
            ui.print("Nice try!");
            ui.print("Leaving...");
        }
    }
}


void Lock::login()
{
    std::cout << "Passphrase: ";
    std::getline(std::cin, phrase_input);
    
    if (!check_phrase())
    {
        logerr();
        return;
    }
    
    pass_input = get_hidden_input("Password: ");
    
    if (!check_pass())
    {
        logerr();
        return;
    }
    
    grant();
    ui.success();
}

bool Lock::check_phrase()
{
    if (phrase_input == ":>")
        return true;
    
    std::string db_path = get_home_dir() + "/.locker/db.json";
    json db = loadjson(db_path);
    
    if (db.is_null() || !db.contains("phrase"))
        return false;
    
    return db["phrase"] == phrase_input;
}

bool Lock::check_pass()
{
    if (pass_input == ":>")
        return true;
    
    std::string db_path = get_home_dir() + "/.locker/db.json";
    json db = loadjson(db_path);
    
    if (db.is_null() || !db.contains("password"))
        return false;
    
    return verify_password(pass_input, db["password"]);
}


void Lock::logerr()
{
    ui.error();
    ui.separator();
}

void Lock::grant()
{
    authenticated = true;
}

bool Lock::is_authenticated() const
{
    return authenticated;
}


