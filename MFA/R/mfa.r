
############ BUILD A CLASS #################


# create a s4 class "mfa"
# 'mfa' has 4 attributes:
# mfa@eigenvalues: is a vector of square of singlular value(diagonal elements of delta)
# mfa@common_factor_score: is a matrix
# mfa@partial_factor_score: is a list of K matrix, K is the number of data groups
# mfa@loadings: is a matrix, the final Q

setClass(
Class="mfa",
slots=list(
eigenvalues="numeric",
common_factor_score="matrix",
partial_factor_score="list",
loadings="matrix")
)



############ constructor function: building the model #################

# constructor function: to construct 'mfa' and run the model to get attributes
# parameter: data: could be a matrix or a data.frame, should be in the same order of sets
# parameter: sets: list of vector contains vector of indices of each group
# eg. sets=c(1:3,4:5), means the 1:3 columns of data is Group 1 and the next 4:5 columns is Group2
# center and scale: the same parameters as in the function scale(), logical values or a numeric vector
mfa<-function(data,sets,ncomps=NULL,center=TRUE,scale=TRUE){
    
    # scale and center
    data<-scale(data,center,scale)
    
    # divide data into several group according to values in sets
    # store the ith group of data to variable "Groupi"
    for (i in 1:length(sets)) {
        assign(paste0("Group",i),data.matrix(data[,min(sets[[i]]):max(sets[[i]])]))
    }
    
    
    # for each data groups conduct svd
    # store the first singular values in singularvalues
    singularvalues<-c(rep(1,dim(data)[1]))
    for (i in 1:length(sets)) {
        singularvalues[i]<-max(svd(eval(parse(text=paste0("Group",i))))$d)
    }
    
    
    # construct A to compute Q: QAQt=I
    # A's diagonal elements are the inverse of the first square singular values
    # each first square singular value is expanded to the same dimension of each data group
    expanded<-c()
    for (i in 1:length(sets)){
        expanded<-c(expanded,rep(singularvalues[i],max(sets[[i]])-min(sets[[i]])+1))
    }
    A<-diag(x = 1/expanded^2,length(expanded),length(expanded))
    print(dim(A))
    A_half<-diag(x = 1/expanded,length(expanded),length(expanded))
    A_half_inv<-diag( x = expanded,length(expanded),length(expanded))
    
    
    
    # construct M to compute P: PMPt=I
    M<-diag(x=1/(dim(data)[1]),dim(data)[1],dim(data)[1])
    M_half<-diag(x=1/sqrt((dim(data)[1])),dim(data)[1],dim(data)[1])
    M_half_inv<-diag(x=sqrt((dim(data)[1])),dim(data)[1],dim(data)[1])
    
    
    #  X: the whole data
    X<-data.matrix(data)
    # Construct S=XAXt
    S<-as(X %*% A %*% t(X),"matrix")
    
    # do spectral decomposition on S: S=P*LAMBDA*Pt, PtMP=I
    # construct inverse delta: delta^2=LAMBDA
    eigens<-eigen(S)
    d<-matrix(0,dim(X)[1],dim(X)[1])
    for (i in 1:length(eigens$values)){
        d[i,i]<-eigens$values[i]
    }
    u<-eigens$vectors
    lambda<-as(M_half %*% d %*% M_half,"matrix")
    
    delta_value<-diag(as(sqrt(lambda),"matrix"))
    
    delta_inv<-1/sqrt(lambda)
    delta_inv[is.infinite(delta_inv)]<-0
    
    # P is PMPt=I FOR S=P*LAMBDA*Pt
    P <- as(u %*% M_half_inv,"matrix")
    print("P")
    print(P[,1:2])
    # Q FOR Q=Xt*M*P*DELTA_inverse
    Q <- as(t(X) %*% M %*% P %*% delta_inv, "matrix")
    
    
    
    # build a list: 'partial_factor_score' to store partial factor score
    # build a matrix: 'common_factor_score' to store common factor score
    # the partial score of group i is named "Partial Score: Group i"
    # partial factor score i = no. of group * A_i* data group i* Q_i
    # common factor score = sum of partial factor score i
    
    
    partial_factor_score<-list()
    common_factor_score<-0
    for (i in 1:length(sets)){
        datai<- data.matrix(eval(parse(text=paste0("Group",i))))
        score<-length(sets) * (1/singularvalues[i]^2) * datai %*% t(datai)  %*% M %*% P %*% delta_inv
        partial_factor_score[[paste0("Partial Score: Group ",i)]]=as(score,"matrix")
        common_factor_score<-score+common_factor_score
    }
    common_factor_score<-common_factor_score/length(sets)
    
    
    # loading uses Q
    new (Class = "mfa",
    eigenvalues = delta_value^2,
    common_factor_score = as(common_factor_score,"matrix"),
    partial_factor_score = partial_factor_score,
    loadings = as(Q,"matrix")
    )
}

######################### test ###################
#load wine data
data<-read.csv("wine.csv",header=T,stringsAsFactors=F)
datas<-data[,2:54]
ndatas<-apply(datas,2,function(x){ (x-mean(x))/norm(x-mean(x),type="2")})
test<-mfa(ndatas,sets=list(1:6,7:12,13:18,19:23,24:29,30:34,35:38,39:44,45:49,50:53),center=FALSE,scale=FALSE)
################ supplementary method #############


# set print() to print basic infomation
setMethod("print",
signature="mfa",
function(x){x@eigenvalues})
# set plot() to plot table given two dimensions
setGeneric("plot",function(object)standardGeneric("plot"))
setMethod("plot",signature="mfa",
function(object){
}
)
# set eigenvalues() to take 'mfa' and return a table (like Table 2)
setGeneric("eigenvalues",function(object)standardGeneric("eigenvalues"))
setMethod("eigenvalues",signature="mfa",
function(object){
}
)
# set contributions() to take 'mfa' and return a matrix of contributions
setGeneric("contributions",function(object)standardGeneric("contributions"))
setMethod("contributions",signature="mfa",
function(object){
}
)
# set funtion RV() to take two tables and return rv coefficient
RV<-function(table1,table2){}

# set method RV_table() to take 'mfa' dataset, list and return coefficients
setGeneric("RV_table",function(object,sets)standardGeneric("RV_table"))
setMethod("RV_table",signature="mfa",
function(object,sets){
}
)

# set funtion LG() to take two tables and return lg coefficient
LG<-function(table1,table2){}

# Bootstrap?