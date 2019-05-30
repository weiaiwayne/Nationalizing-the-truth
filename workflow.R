
library(httr)
library(data.table)
library(dplyr)
library(tidyverse)
library(tidyr)
library(lubridate)
library(scales)
library(quanteda)
library(ggplot2) 
library(ggthemes)
library(stringr)
library(reshape2)


# The URL of the update_weixin API
url_wxupdate <- "https://wechatscope.jmsc.hku.hk/api/update_weixin_public?days="

# Send API request: 2 = censored info in the past two days
ceninfo <- GET(url = paste0(url_wxupdate,7))

# Process content of the API request
ceninfo_content <- content(ceninfo)

# Convert the content to a dataframe
ceninfo <- rbindlist(ceninfo_content, fill=TRUE)

# number of censored articles by accounts

ceninfo$censored_msg <- gsub("该内容已被发布者删除","Deleted_by_the_account_owner",ceninfo$censored_msg)
ceninfo$censored_msg <- gsub("此内容因违规无法查看","Violating_internet_laws",ceninfo$censored_msg)
ceninfo$censored_msg <- gsub("此内容被多人投诉，相关的内容无法进行查看。","Violating_internet_laws",ceninfo$censored_msg)
ceninfo$censored_msg <- gsub("此内容被投诉且经审核涉嫌侵权，无法查看。","Copyright_infringement",ceninfo$censored_msg)
ceninfo$censored_msg <- gsub("此帐号已被屏蔽,","Account_blocked",ceninfo$censored_msg)
ceninfo$censored_msg <- gsub("该公众号已迁移","Account_changed",ceninfo$censored_msg)

byaccounts <- ceninfo %>% 
  group_by(nickname, censored_msg) %>% 
  summarise(count = length(unique(title)))  

byaccounts_wide <- spread(byaccounts, censored_msg, count)

byaccounts_wide[is.na(byaccounts_wide)] <- 0

byaccounts_wide$total_takedown <- byaccounts_wide$Account_blocked+byaccounts_wide$Account_changed+byaccounts_wide$Copyright_infringement+byaccounts_wide$Deleted_by_the_account_owner+byaccounts_wide$Violating_internet_laws

#save(byaccounts_wide, file = "saveddata.rda")
write.csv(byaccounts_wide,"byaccounts_wide.csv",row.names=FALSE)
