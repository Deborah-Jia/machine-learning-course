# install.packages('ggplot2')
# install.packages('lubridate')
# install.packages('ddply')
# install.packages('data.table')
# install.packages('caret')
rm(list =ls())
library(ggplot2)
library(lubridate)
library(plyr)
library(data.table)
library(caret)

GetBikeData <- function(filePath) {
  dt <- fread(filePath)
  dt$quarter <- factor(dt$season, labels = c("Q1", "Q2", "Q3", "Q4"))
  dt$weather <- factor(mapvalues(dt$weather, from = c(1, 2, 3, 4), to = c("Good", "Normal", "Bad", "Very Bad")))
  dt$hour    <- factor(hour(ymd_hms(dt$datetime)))
  dt$times   <- as.POSIXct(strftime(ymd_hms(dt$datetime), format="%H:%M:%S"), format="%H:%M:%S")
  dt$weekday <- wday(ymd_hms(dt$datetime))
  return(dt)
}

bikeTrain <- GetBikeData("~/Desktop/machine-learning-course/data/bike_rental/bike_rental_train.csv")
bikeTrain 


ggplot(bikeTrain, aes(x=count)) + geom_histogram() 

RootMeanSquaredError <- function(real_value, predicted_value) {
  return(sqrt(mean((real_value - predicted_value) ^ 2)))
}

bikeTrain$prediction_model_zero <- 0
bikeTrain
RootMeanSquaredError(bikeTrain$count, bikeTrain$prediction_model_zero)

bikeTrain$prediction_model_200 <- 200
RootMeanSquaredError(bikeTrain$count, bikeTrain$prediction_model_200)

bikeTrain$prediction_model_median <- median(bikeTrain$count)
RootMeanSquaredError(bikeTrain$count, bikeTrain$prediction_model_median)

bikeTrain$prediction_model_mean <- mean(bikeTrain$count)
RootMeanSquaredError(bikeTrain$count, bikeTrain$prediction_model_mean)

ModelByMean <- function(train, test) {
  new_test = copy(test)
  new_test$prediction <- mean(train$count)
  return(new_test$prediction)
}
ModelByMean(bikeTrain, bikeTrain)
RootMeanSquaredError(bikeTrain$count, ModelByMean(bikeTrain, bikeTrain))

# Idea 进化版的分组和总结！
bikeTrain[, .(count = mean(count)), by=.(quarter)]

# Prediction 进化版的重新命名，太酷了吧！
bikeTrain[quarter == "Q1", prediction_model_by_quarter := 71.90552] #小眼睛跟 copy()一个道理
bikeTrain[quarter == "Q2", prediction_model_by_quarter := 160.94075]
bikeTrain[quarter == "Q3", prediction_model_by_quarter := 186.99487]
bikeTrain[quarter == "Q4", prediction_model_by_quarter := 154.78713]
RootMeanSquaredError(bikeTrain$count, bikeTrain$prediction_model_by_quarter) # 比上次的小多了

# Stages of the previous block: idea, model fit and model evaluation
ModelByQuarter <- function(train, test) {
  new_test = copy(test)
  for (q in unique(train$quarter)) {
    new_test[quarter == q, prediction := mean(train[quarter == q]$count) ]
  }
  return(new_test$prediction)
}

RootMeanSquaredError(bikeTrain$count, ModelByQuarter(bikeTrain, bikeTrain))

# 通过分组把变量之间的差距缩小，进而减小RMSE
ModelByQuarterWorkingday <- function(train, test) {
  new_test = copy(test)
  for (q in unique(train$quarter)) {
    for (w in unique(train$workingday)) { 
      new_test[quarter == q & workingday==w, 
               prediction := mean(train[quarter == q & workingday == w ]$count) ]
    }
  }
  return(new_test$prediction)
}

RootMeanSquaredError(bikeTrain$count, ModelByQuarterWorkingday(bikeTrain, bikeTrain))

