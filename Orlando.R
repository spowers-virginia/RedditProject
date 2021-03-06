library(anytime)
library(tidyverse)
library(tidytext)
library(lubridate)



id <- "1Ij59kWoNUNQdNj3q3qqvmf0K1tBjqrz7"
id.july <- "1IlnG19Z5Kih8caXAAz0nfeHuib_YiLFl"
# id.aug <- 

orlando.june  <- read_csv(sprintf("https://docs.google.com/uc?id=%s&export=download", id))
orlando.july <- read_csv(sprintf("https://docs.google.com/uc?id=%s&export=download", id.july))
# orlando.aug <- read_csv(sprintf("https://docs.google.com/uc?id=%s&export=download", id.oct))

orlando <- rbind(orlando.june, orlando.july)

########
orlando.data <- orlando %>% 
  dplyr::select(body, created_utc, subreddit) %>%
  mutate(ID = 1:length(orlando$created_utc))

rates.orlando <- orlando.data %>% 
  mutate(hour = floor_date(anytime(created_utc), unit = "1 hour")) %>%
  count(hour) %>%
  rename(count = n)
View(rates.orlando)

ggplot(rates.orlando, aes(x = hour, y = count)) + geom_point(size = .001)


time.data.o <- orlando$created_utc[orlando$created_utc >= as.numeric(as.POSIXct("2016-06-12 07:00:00"))]
time.data.o <- time.data.o - min(time.data.o)+ 1
time.data.o <- time.data.o[time.data.o <= 4838400]

range(time.data.o)
hist(time.data.o)
fit.lnorm.o <- fitdist(time.data.o, "lnorm")
summary(fit.lnorm.o)
plot(fit.lnorm.o)

max(rates.orlando$count)





########
# Define the functions I want for quick analysis #

# sentiment #
sentimental <- function(dataframe){
  d <- data.frame(dataframe)
  d$body <- as.character(d$body)
  d <- d %>% 
    unnest_tokens(word, body, token = "words", format = "text") %>%
    inner_join(get_sentiments("bing"), by = "word") %>%
    count(sentiment, ID) %>%
    spread(sentiment, n, fill = 0) 
  dataframe <- left_join(dataframe, d, by = "ID") %>%
    replace_na(list(negative = 0, positive = 0)) %>%
    mutate(sentiment = positive - negative, negative = -1*(negative))
} 

########


# Select the portions I want #
orlando.data <- orlando %>% 
  dplyr::select(body, created_utc, subreddit) %>%
  mutate(ID = 1:length(orlando$created_utc))

#######

# Use formula to get the sentiments #
orlando.data <- sentimental(orlando.data)
plotdata.orlando <- orlando.data %>% gather("sent","n", 5:6 )


# Calculate number of tweets per hour #
rates.orlando <- orlando.data %>% 
  mutate(hour = floor_date(anytime(created_utc), unit = "1 hour")) %>%
  count(hour) %>%
  rename(count = n)

# Average Sentiment per hour #
avg.orlando.data <- orlando.data %>%   
  mutate(hour = floor_date(anytime(created_utc), unit = "1 hour")) %>%
  group_by(hour) %>% 
  summarise(avgsent = mean(abs(sentiment)), avgpos = mean(positive), avgneg = mean(negative))

avg.day <- orlando.data %>%
  mutate(hour = floor_date(anytime(created_utc), unit = "12 hour")) %>%
  group_by(hour) %>% 
  summarise(avgsent = mean(abs(sentiment)), avgpos = mean(positive), avgneg = mean(negative), varsent = var(sentiment))

# Join them
rates.orlando <- rates.orlando %>% left_join(avg.orlando.data)

hourly.pos.neg.orlando <- rates.orlando %>% gather("type", "n", 4:5)

# Plot number of tweets per hour and sentiment #
# count and sentiment
ggplot(avg.orlando.data, aes(x=hour, y = avgsent)) + geom_point(size = .001)
ggplot(rates.orlando, aes(x = hour, y = count)) + geom_point(size = .001)
ggplot(rates.orlando, aes(x = hour, y = log(count))) + geom_point(size = .001)


# Negative/Positive by time
ggplot(plotdata.orlando, aes(x = anytime(created_utc), y = n, color = sent )) + 
  geom_point(size = .001) 

# Sentiment by time
ggplot(plotdata.orlando, aes(x= anytime(created_utc), y = sentiment)) + geom_point(size = .001) 

# Avg pos/negative by hour
ggplot(hourly.pos.neg.orlando, aes(x=hour, y = n, color= type)) + geom_point(size = .001)


###
# by half day #
ggplot(avg.day  %>%
         gather("type", "n", 3:4), aes(x=hour, y = n, color = type)) + geom_point(size = .001)

ggplot(avg.day, aes(x=hour, y = varsent)) + geom_point(size = .001)

