NAME = locker

CFLAGS = -Wall -Wextra -Werror
C = c++
VERSION = -std=c++17
SRCS = $(wildcard srcs/*.cpp) $(wildcard srcs/impl/*.cpp)
OBJS = $(SRCS:.cpp=.o)
HEADER_PATH = ./include/

all: $(NAME)

$(NAME): $(OBJS)
	$(C) $(VERSION) $(CFLAGS) -I$(HEADER_PATH) $(OBJS) -o $(NAME)

%.o: %.cpp
	$(C) $(VERSION) $(CFLAGS) -I$(HEADER_PATH) -c $< -o $@

clean:
	rm -f $(OBJS)

fclean: clean
	rm -f $(NAME)

re: fclean all
