install.packages("caret")
install.packages("lattice")
install.packages("ggplot2")
install.packages("gam")
install.packages('ade4')
install.packages('rpart')
install.packages("rpart.plot")
install.packages("forecast")
install.packages("ModelMetrics")
library(ModelMetrics)
library(caret)
library(lattice)
library(ggplot2)
library(gam)
library(ade4)
library(rpart)
library(rpart.plot)
library(forecast)

#read data from local file
rawtraindata <-  read.csv(file="/Users/eavy/Downloads/7390/train.csv", header=TRUE, sep=",")
head(rawtraindata, n=5)

###################################################################################!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
na <- colSums(is.na(rawtraindata))
nafreq <- na/nrow(rawtraindata)
colnames(rawtraindata[, which(nafreq > 0.5)])
colToDel <- which(nafreq > 0.5)
new_train <- rawtraindata[-colToDel]

########Selecting the categoical columns############
#using c() to return a vector and paste() to print the names again everytime instead of just displaying the number and using
# sep="" without which the column numbers will be displayed with a spcae causing error.
categoricalcolumns <- c(paste("Product_Info_", c(1:3,5:7),sep=""), paste("Employment_Info_", c(2,3,5), sep=""), 
                        paste("InsuredInfo_", 1:7, sep=""), paste("Insurance_History_", c(1:4,7:9), sep=""), paste("Family_Hist_1"),
                        paste("Medical_History_", c(2:9, 11:14, 16:23, 25:31, 33:41),sep=""),"Response")

######Selecting the discrete columns############
discretecolumns <- c("Id","Medical_History_1", 
                     paste("Medical_Keyword_", 1:48, sep=""))

#######Selecting the continious columns#########
continiouscolumns <- c("Product_Info_4", "Ins_Age", "Ht", "Wt", "BMI", "Employment_Info_1", "Employment_Info_4", 
                       "Employment_Info_6", "Insurance_History_5", "Family_Hist_2", "Family_Hist_4", 
                       "Family_Hist_5")

#Displaying the columns
categoricalcolumns
discretecolumns
continiouscolumns

#Combining the data with the column names
rawdatacategorical <- rawtraindata[, categoricalcolumns]
rawdatadiscrete <- rawtraindata[, discretecolumns]
rawadatacontinious <- rawtraindata[, continiouscolumns]

str(rawdatacategorical)

#Finding the columns with missing values from categorical data
sum(is.na(rawdatacategorical))

# installing the ade4 libarary to use acm.disjonctif() because our dataframe only contains factors
#acm.disjonctif an utility giving the complete disjunctive table of a factor table.
df_categorical <-acm.disjonctif(rawdatacategorical[c(1:60)]) #selecting first 60 columns except the response column
head(df_categorical, n=2)

# selecting the response value seperately so that we don't categorize it
responsevalue <-rawdatacategorical[, c(61)]

#Combining the categorized values with the response value into one dataframe
df_categoricalbinded <- cbind(df_categorical,responsevalue)
head(df_categoricalbinded, n=2)
str(df_categoricalbinded)

########Binding everything together###############
newrawtraindata <- cbind(rawadatacontinious,rawdatadiscrete,df_categoricalbinded)
ncol(newrawtraindata)
summary(newrawtraindata)

#make processing for independent variables
train_data <- newrawtraindata[,-892]
head(train_data)
target_data <- newrawtraindata[, 892]
head(target_data)

str(train_data)

#Delete the variables that approximate the constant
#zerovar <- nearZeroVar(train_data)
#mydata <- train_data[,-zerovar]
#str(mydata)

mydata <- train_data
#Data preprocessing (normalization, missing value processing)
#Process <- preProcess(newdata1)
#newdata2 <- predict(Process, newdata1)
boxplot(mydata$Employment_Info_4)
boxplot(mydata$Employment_Info_6)
boxplot(mydata$Family_Hist_2)
boxplot(mydata$Family_Hist_4)
boxplot(mydata$Family_Hist_5)
boxplot(mydata$Medical_History_1)

mydata$Employment_Info_4[is.na(mydata$Employment_Info_4)] <- median(mydata$Employment_Info_4, na.rm = TRUE)
#Filling missing values with mean value for Employment_Info_6
mydata$Employment_Info_6[is.na(mydata$Employment_Info_6)] <- mean(mydata$Employment_Info_6, na.rm = TRUE)
#Filling missing values with max value for Insurance_History_5
#----------mydata$Insurance_History_5[is.na(mydata$Insurance_History_5)] <- median(mydata$Insurance_History_5, na.rm = TRUE)
#Filling missing values with min value for Family_Hist_2
mydata$Family_Hist_2[is.na(mydata$Family_Hist_2)] <- mean(mydata$Family_Hist_2, na.rm = TRUE)
#Filling missing values with mean value for Family_Hist_3
#----------mydata$Family_Hist_3[is.na(mydata$Family_Hist_3)] <- median(mydata$Family_Hist_3, na.rm = TRUE)
#Filling missing values with mean value for Family_Hist_4
mydata$Family_Hist_4[is.na(mydata$Family_Hist_4)] <- mean(mydata$Family_Hist_4, na.rm = TRUE)
#Filling missing values with min value for Family_Hist_5
mydata$Family_Hist_5[is.na(mydata$Family_Hist_5)] <- median(mydata$Family_Hist_5, na.rm = TRUE)
#Filling missing values with mean value for Medical_History_1
mydata$Medical_History_1[is.na(mydata$Medical_History_1)] <- median(mydata$Medical_History_1, na.rm = TRUE)
str(mydata)

#store id in memory
id <- mydata[,13]
myData <- mydata[, -13]

train_dataF <- data.frame(target_data, myData)

#Use the sbf function to implement the filtering method, here is the importance of using random forests to evaluate variables
newdatafinal <- lm(train_dataF$target_data~., data = train_dataF)
summary(newdatafinal)
index <- summary(newdatafinal)$coefficients[,4] <= 0.01
str(index[index == TRUE])
indexname <- names(index[index == TRUE])[2:65]
#df <- data.frame(newdatafinal)
#testDelete <- step(data.filter, direction = "backward")

cleanData <- train_dataF[indexname]
str(cleanData)
cleanDataFrame <- data.frame(id, target_data, cleanData)
str(cleanDataFrame)
dim(cleanData)
# cleanDataFrame$target_data <- as.factor(cleanDataFrame$target_data)

write.csv(cleanDataFrame, file = "newRawData.csv")

#set.seed(1)
#indxTrain <- createDataPartition(y = cleanDataFrame$target_data,p = 0.8,list = FALSE)
#train_data <- cleanDataFrame[indxTrain,]
#test_data <- cleanDataFrame[-indxTrain,]

#######################################################################################################



### get train and test data
train <- cleanDataFrame
train$target_data <- as.factor(train$target_data)

dim(train) 
#Sample Indexes
set.seed(80)
#indexes = sample(1:nrow(train), size=0.75*nrow(train))
indxTrain <- createDataPartition(y = train$target_data,p = 0.8,list = FALSE)
# Split data
train_data <- train[indxTrain,]
test_data <- train[-indxTrain,]




################################ Decision Tree #############################################

dTree <-  rpart(target_data ~ ., data = cleanDataFrame, method = "anova",cp=0.01)
## Prune the tree
printcp(dTree) 
plotcp(dTree) 

myPre <- predict(dTree, test_data)
ModelMetrics::rmse(myPre, test_data$target_data)

# Round the predict result
pResult <- round(myPre, digits = 0) 
pResult[pResult<1] <- 1
pResult[pResult>8] <- 8

confusionMatrix (pResult, test_data$target_data)
rpart.plot(dTree) # Print the decision tree plot
mean(myPre == test_data$target_data) # 26.378%

#############################################################################




################################# get train and test data #############################################

train <- read.csv(file = "/Users/eavy/Downloads/preprocess.csv", header=TRUE, sep=",")
#train$target_data <- as.numeric(train$target_data)

dim(train) 
#Sample Indexes
set.seed(80)
indexes = sample(1:nrow(train), size=0.75*nrow(train))
# Split data
train_data1 = train[indexes,]
dim(train_data1)  
test_data1 = train[-indexes,]
dim(test_data1)
#############################################################################################



################################# Other ######################################################################################
tree_model <- rpart(Response ~ ., data = train, method = "anova",cp=0.001)
myPre1 <- predict(tree_model, test_data1)
ModelMetrics::rmse(myPre1, test_data1$Response)
pResult1 <- round(myPre1, digits = 0)
pResult1[pResult1<1] <- 1
pResult1[pResult1>8] <- 8
confusionMatrix (pResult1, test_data1$Response)
rpart.plot(tree_model)


accuracy( test_data$target_data,myPre)




View(myPre)
summary(dTree) # detailed summary of splits
rpart.plot(dTree)



################################# get train and test data #############################################
train <- cleanDataFrame
train$target_data <- as.numeric(train$target_data)

dim(train) 
#Sample Indexes
set.seed(80)
indexes = sample(1:nrow(train), size=0.75*nrow(train))
# Split data
train_data = train[indexes,]
dim(train_data)  
test_data = train[-indexes,]
dim(test_data)

################################################ get train and test data #############################################







## Predict the target_data variable using test dataset
View(test_data)
myPre <- predict(dTree, data = test_data, type = "anova")
# Calculate accuracy
mean(myPre == we) # 22.918%
length(myPre)

## Prune the tree
printcp(dTree)   # display the results 
plotcp(dTree)   # visualize cross-validation results
pruned_tree <- prune(dTree, cp=0.011)
rpart.plot(pruned_tree)

myPre_pruned <- predict(pruned_tree, data = test_data)
mean(myPre_pruned == test_data$target_data) # 26.378%





##########################################################################################

ct <- rpart.control(xval=10, minsplit=20, cp=0.011)
dTree <-  rpart(target_data ~ ., data = train_data, method = "class", control = ct)
myPre <- predict(dTree, data = test_data, type = "class")
DAccuracy <- mean(myPre == test_data$target_data)
DAccuracy


summary(dTree) # detailed summary of splits
rpart.plot(dTree)
plotcp(dTree) # visualize cross-validation results


## Predict the target_data variable using test dataset
View(test_data)
myPre <- predict(dTree, data = test_data, type = "class")
# Calculate accuracy
DAccuracy <- mean(myPre == test_data$target_data)


#accuracy(myPre,test_data$target_data)

## Prune the tree
pruned_tree <- prune(dTree, cp=0.0278)









