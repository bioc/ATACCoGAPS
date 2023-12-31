#function to determine matching pathways for an individual pattern
paths <- function(patGenes, pathways, pval_cut, pAdjustMethod) {
  
  #test for pathway overlap with newGeneOverlap function from GeneOverlap
  #package
  testList <- vector(mode = "list", length = length(pathways))
  for(i in seq_along(pathways)) {
    tmpoverlap <- GeneOverlap::newGeneOverlap(patGenes, unlist(pathways[i]))
    tmptest <- GeneOverlap::testGeneOverlap(tmpoverlap)
    testList[i] <- tmptest
  }
  
  #get p-values and threshold returned results
  l <- lapply(testList, GeneOverlap::getPval)
  pvals <-unlist(l)
  pvals <- p.adjust(pvals, pAdjustMethod)
  inds <- which(pvals < pval_cut)
  gene_ov_objs <- testList[inds]
  paths <- pathways[inds]
  nms <- names(paths)
  if(length(gene_ov_objs) > 0) {
    sigpvals <- unlist(lapply(gene_ov_objs, GeneOverlap::getPval))
    df <- data.frame(pathway = nms, PValue = sigpvals)
    df <- df[order(df$PValue),]
  }
  else{df <- NULL}
  return(list(gene_overlaps = gene_ov_objs, matched_pathways = paths,
              pathway_names = nms, summaryTable = df))
}



#' Matches list of genes to pathways
#'
#' Takes the result of the genePatternMatch function and finds significantly
#' enriched pathways for each pattern.
#'
#' @param gene_list Result from the genePatternMatch function, a list of genes
#'   for each pattern
#' @param pathways List of pathways to perform gene enrichment on. Recommended
#'   to download using msigdbr (see examples)
#' @param p_threshold significance level to use in enrichment analysis
#' @param pAdjustMethod multiple testing correction method to apply using the
#'   p.adjust options (e.g. "BH")
#'
#' @return List of gene overlap objects, pathways with significant overlap and
#'   pathway names for each pattern
#' @examples data(schepCogapsResult)
#' data(schepGranges)
#' library(Homo.sapiens)
#'
#' genes <- genePatternMatch(cogapsResult = schepCogapsResult,
#'  generanges = schepGranges, genome = Homo.sapiens)
#' 
#' library(dplyr)
#' pathways = msigdbr::msigdbr(species = "Homo sapiens", category ="H") %>% 
#' dplyr::select(gs_name, gene_symbol) %>% as.data.frame()
#'
#' matchedPathways = pathwayMatch(genes, pathways, p_threshold = 0.001)
#' @export
pathwayMatch <- function(gene_list, pathways, p_threshold = 0.05,
                        pAdjustMethod = "BH") {
  
  #get pathway names
  pathways[,1] <- as.factor(pathways[,1])
  pathwayNames <- levels(pathways[,1])
  
  #convert downloaded data frame to list for use with GeneOverlap package
  pathgene_list <- vector(mode = "list", length = length(pathwayNames))
  for(i in seq_along(pathwayNames)){
    tmpgene_list <- pathways[which(pathways[,1]==pathwayNames[i]), 2]
    pathgene_list[[i]] <- tmpgene_list
  }
  names(pathgene_list) <- pathwayNames
  
  #run paths function for each pattern
  filenames <- vector(mode = "list", length = length(gene_list))
  for(i in seq_along(gene_list)) {
    tmpMatches <- suppressWarnings(paths(gene_list[[i]],
                                        pathgene_list, p_threshold,
                                        pAdjustMethod))
    nam <- paste("pattern", i, "genes", sep = "")
    filenames[i] <- nam
    assign(nam, tmpMatches)
  }
  
  #put all patterns into a double nested list and return as result
  ind <-paste(filenames, collapse = ",")
  pathwayMatches <- eval(parse(text = paste("list(", ind, ")")))
  return(pathwayMatches)
}






