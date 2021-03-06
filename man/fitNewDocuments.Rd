% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fitNewDocuments.R
\name{fitNewDocuments}
\alias{fitNewDocuments}
\title{Fit New Documents}
\usage{
fitNewDocuments(model = NULL, documents = NULL, newData = NULL,
  origData = NULL, prevalence = NULL, betaIndex = NULL,
  prevalencePrior = c("Average", "Covariate", "None"),
  contentPrior = c("Average", "Covariate"), returnPosterior = FALSE,
  returnPriors = FALSE, designMatrix = NULL, test = TRUE,
  verbose = TRUE)
}
\arguments{
\item{model}{the originally fit STM object.}

\item{documents}{the new documents to be fit. These documents must be in the stm format and
be numbered in the same way as the documents in the original model with the same dimension of vocabulary.
See the \pkg{quanteda} feature \link[quanteda]{dfm_select} for a way to do this.}

\item{newData}{the metadata for the prevalence prior which goes with the unseen documents. As in
the original data this cannot have any missing data.}

\item{origData}{the original metadata used to fit the STM object.}

\item{prevalence}{the original formula passed to prevalence when \code{stm} was called. The function
will try to reconstruct this.}

\item{betaIndex}{a vector which indicates which level of the content covariate is used
for each unseen document. If originally passed as a factor, this can be passed as a factor or 
character vector as well but it must not have any levels not included in the original factor.}

\item{prevalencePrior}{three options described in detail below.  Defaults to "Average" when
\code{data} is not provided and "Covariate" when it is.}

\item{contentPrior}{two options described in detail below. Defaults to "Average" when 
\code{betaIndex} is not provided and "Covariate" when it is.}

\item{returnPosterior}{the function always returns the posterior mode of theta
(document-topic proportions),  If set to TRUE this will return the full variational
posterior.  Note that this will return a dense K-by-K matrix for every document
which can be very memory intensive if you are processing a lot of documents.}

\item{returnPriors}{the function always returns the options that were set for the prior
(either by the user or chosen internally by the defaults).  In the case of content covariates
using the covariate prior this will be a set of indices to the original beta matrix so as
not to make the object too large.}

\item{designMatrix}{an option for advanced users to pass an already constructed design matrix for
prevalence covariates.  This will override the options in \code{newData}, \code{origData} and
\code{test}.  See details below- please do not attempt to use without reading carefully.}

\item{test}{a test of the functions ability to reconstruct the original functions.}

\item{verbose}{Should a dot be printed every time 1 percent of the documents are fit.}
}
\value{
an object of class fitNewDocuments

\item{theta}{a matrix with one row per document contain the document-topic proportions at the posterior mode}
\item{eta}{the mean of the variational posterior, only provided when posterior is requested. 
Matrix of same dimension as theat}
\item{nu}{a list with one element per document containing the covariance matrix of the variational posterior.
Only provided when posterior is requested.}
\item{phis}{a list with one element per K by V' matrix containing the variational distribution for each token 
(where V' is the number of unique words in the given document.  They are in the order of appearence in the document. 
For words repeated more than once the sum of the column is the number of times that token appeared.  This is only
provided if the posterior is requested.}
\item{bound}{a vector with one element per document containing the approximate variational lower bound. This is only
provided if the posterior is requested.}
\item{beta}{A list where each element contains the unlogged topic-word distribution for each level of the content covariate.
This is only provided if prior is requested.}
\item{betaindex}{a vector with one element per document indicating which element of the beta list the documents pairs with.
This is only provided if prior is requested.}
\item{mu}{a matrix where each column includes the K-1 dimension prior mean for each document. This is only provided if prior is requested.}
\item{sigma}{a K-1 by K-1 matrix containing the prior covariance. This is only provided if prior is requested.}
}
\description{
A function for predicting thetas for an unseen document based on the previously fit model.
}
\details{
Due to the existence of the metadata in the model, this isn't as simple as in models
without side information such as Latent Dirichlet Allocation. There are four scenarios:
models without covariate information, models with prevalence covariates only, models with
content covariates only and models with both.  When there is not covariate information the
choice is essentially whether or not to use prior information.

We offer three types of choices (and may offer more in the future):
\describe{
\item{"None"}{No prior is used.  In the prevalence case this means that the model simply
maximizes the likelihood of seeing the words given the word-topic distribution.  This will
in general produce more sharply peaked topic distributions than the prior. This can be used
even without the covariates.  This is not an option for topical content covariate models.  If
you do not observe the topical content covariate, use the "Average" option.} 
\item{"Average"}{We use a prior that is based on the average over the documents in the training
set.  This does not require the unseen documents to observe the covariates.  In a model that originally
had covariates we need to adjust our estimate of the variance-covariance matrix sigma to accomodate that
we no longer have the covariate information.  So we recalculate the variance based on what it would have
been if we didn't have any covariates.  This helps avoid an edge case where the covariates are extremely
influential and we don't want that strength applied to the new covariate-less setting.  In the case of 
content covariates this essentially use the \code{\link{sageLabels}} approach to create a
marginalized distribution over words for each topic.
}
\item{"Covariate"}{We use the same covariate driven prior that existed in the original model.
This requires that the test covariates be observed for all previously unseen documents.}
}

If you fit a document that was used during training with the options to replicate the initial
\code{\link{stm}} model fit you will not necessarily get exactly the same result.  \code{\link{stm}}
updates the topic-word distributions last so they may shifted since the document-topic proportions
were updated.  If the original model converged, they should be very close.

By default the function returns only the MAP estimate of the normalized document-topic proportions
theta.  By selecting \code{returnPrior=TRUE} you can get the various model parameters used to complete
the fit.  By selecting \code{returnPosterior=TRUE} you can get the full variational posterior.  Please
note that the full variational posterior is very memory intensive.  For a sense of scale it requires an
extra \eqn{K^2 + K \times (V'+1) + 1} doubles per document where V' is the number of unique tokens in the document.

\strong{Testing:} Getting the prevalence covariates right in the unseen documents can be tricky.  However
as long as you leave \code{test} set to \code{TRUE} the code will automatically run a test to make sure
that everything lines up.  See the internal function \code{\link{makeDesignMatrix}} for more on what is 
going on here.

\strong{Passing a Design Matrix}  Advanced users may wish to circumvent this process and pass their
own design matrix possibly because they used their own function for transforming the original input
variables.  This can be done by passing the design matrix using the \code{designMatrix} argument
The columns need to match the ordering of the design matrix for the original \code{stm} object.  
The design matrix in an stm model called \code{stmobj} can be found in \code{stmobj$settings$covariates$X} 
which can in turn be used to check that you have formatted your result correctly. If you are going to 
try this we recommend that you read the documentation for \code{\link{makeDesignMatrix}} to understand
some of the challenges involved.

If you want even more fine-grained control we recommend you directly use the 
optimization function \code{\link{optimizeDocument}}
}
\examples{
#An example using the Gadarian data.  From Raw text to fitted model.
temp<-textProcessor(documents=gadarian$open.ended.response,metadata=gadarian)
out <- prepDocuments(temp$documents, temp$vocab, temp$meta)
set.seed(02138)
#Maximum EM its is set low to make this run fast, run models to convergence!
mod.out <- stm(out$documents, out$vocab, 3, prevalence=~treatment + s(pid_rep), 
              data=out$meta, max.em.its=5)
fitNewDocuments(model=mod.out, documents=out$documents[1:5], newData=out$meta[1:5,],
               origData=out$meta, prevalence=~treatment + s(pid_rep),
               prevalencePrior="Covariate")
}
\seealso{
\code{\link{optimizeDocument}} \code{\link{make.heldout}} \code{\link{makeDesignMatrix}}
}

