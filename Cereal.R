# libraries
library(scales)
library(forecast)
library(gplots)
library(reshape)
library(leaps)
library(caret)
library(lattice)
library(ggplot2)
library(factoextra)

# load the data
grains <- read.csv("Edible_grains.csv", header = TRUE)
cluster.df <- grains

# summary and dim of the data
summary(cluster.df)
sapply(cluster.df, class)
dim(cluster.df)

# check number of missing values
data.frame(miss.val=sapply(cluster.df, function(x)
  sum(length(which(is.na(x))))))

# pie chart for variety
variety <- table(cluster.df$Variety)
pie(variety,
    labels = paste(round(prop.table(variety)*100), "%", sep = ""),
    labelcex=0.9,
    main = "Variety of Cereals",
    col = rainbow(length(variety)))
legend("topleft", legend = names(variety), fill = rainbow(length(variety)))

# pie chart for producer
producer <- table(cluster.df$Producer)
pie(producer,
    labels = paste(round(prop.table(producer)*100), "%", sep = ""),
    labelcex=0.9,
    main = "Producer of Cereals",
    col = rainbow(length(producer)))
legend("topleft", inset=c(-0.02, 0.2),legend = names(producer), fill = rainbow(length(producer)))

# remove data
cluster.df<-cluster.df[, -c(1:3)]

# replace negative value to 0
cluster.df<- replace(cluster.df,cluster.df<0, 0)
head(cluster.df)

# normalize the data
cluster.norm <- preProcess(cluster.df, method=c("center", "scale"))
cluster.norm.df <- predict(cluster.norm, cluster.df)
summary(cluster.norm.df)

# run kmeans algorithm
set.seed(2)
clusterkm <- kmeans(cluster.norm.df,4)
clusterkm$centers # show centroids
clusterkm$withinss #within ss
clusterkm$betweenss #between ss

# plot centroids
# plot an empty scatter plot
plot(c(0), xaxt = 'n', ylab = "", type = "l",
     ylim = c(min(clusterkm$centers), max(clusterkm$centers)), xlim = c(0, 13))
axis(1, at = c(1:13), labels = names(cluster.df), las=2)

# plot centroids
for (i in c(1:4)){
  lines(clusterkm$centers[i,], lty = i, lwd = 2, col = ifelse(i %in% c(1, 3, 5, 7),
                                                              "red","green"))}
# name clusters
text(x = 0.5, y = clusterkm$centers[, 1], labels = paste("Cluster", c(1:4)), srt=45)

dist(clusterkm$centers) # gives distance between centers
clusterkm # betweenss/ totalss should be higher
clusterkm$withinss # if it's 0 then very homogenous clusters we want homogenius
clusterkm$betweenss
sum(clusterkm$withinss)
mean(clusterkm$withinss)
clusterkm$cluster

clusterWithinSS.df <- data.frame(k = seq(1, 10, 1), AvgWithinSS = rep(0, 10)) #rep just repeats a value (0 in this case) 14 times. We are just initiating accuracy

# compute AvgWithinSS for different k
for(i in 1:10) {
  clusterWithinSS.df[i,2] <- mean(kmeans(cluster.norm.df, i)$withinss)
}
clusterWithinSS.df
plot(clusterWithinSS.df$AvgWithinSS ~ clusterWithinSS.df$k, xlab="Number of clusters", ylab = "Average WithinSS")

fviz_cluster(clusterkm, cluster.norm.df)

cluster.df$kmeans<-as.factor(clusterkm$cluster)
summary(cluster.df)

# for numerical variable prediction
aggregate(cluster.df$ratings,by=list(cluster.df$kmeans),FUN=mean)

# set row names to the utilities column
row.names(cluster.norm.df) <- grains[,1]

# compute normalized distance using Euclidean method
clusterdnorm <- dist(cluster.norm.df[,-16], method = "euclidean")
clusterdnorm

# in hclust() set argument method = ward.D
clusterhc1 <- hclust(clusterdnorm, method = "ward.D")
plot(clusterhc1, main = "Cluster Dendrogram")

# in hclust() set argument method = single
clusterhc2 <- hclust(clusterdnorm, method = "single")
plot(clusterhc2, main = "Cluster Dendrogram")

# in hclust() set argument method = complete
clusterhc3 <- hclust(clusterdnorm, method = "complete")
plot(clusterhc3, main = "Cluster Dendrogram")

# in hclust() set argument method = average
clusterhc4 <- hclust(clusterdnorm, method = "average")
plot(clusterhc4, main = "Cluster Dendrogram")

#Get membership numbers
clusters <- cutree(clusterhc1, k = 4)
rect.hclust(clusterhc1, k = 4, border = "red")

# make a as factor and add in main dataset
cluster.df$ward<-as.factor(clusters)
summary(cluster.df)

grains$ward<-as.factor(clusters)
summary(grains)

# for categorical variable prediction
table(grains$Producer,grains$ward)

# for numerical variable prediction
aggregate(cluster.df$ratings,by=list(cluster.df$ward),FUN=mean)

# heatmap
row.names(cluster.norm.df) <- paste(clusters, ": ", row.names(cluster.norm.df), sep = "")
heatmap(as.matrix(cluster.norm.df[,-13]), Colv = NA, hclustfun = hclust,
        col=rev(paste("gray",1:99,sep="")))

