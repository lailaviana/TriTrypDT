#pacotes ------------
library(dplyr)
library(purrr)
library(stringr)
library(httr)
library(xml2)
library(data.table)
library(tidyr)

#baixando a página ------------
u_tritrypdb <- "https://tritrypdb.org/common/downloads/Current_Release/"
r_tritrypdb <- httr::GET(u_tritrypdb, write_disk(path = "tritrypdb.html", overwrite = TRUE))

#manipulacao dos dados obtidos --------- 
names <- r_tritrypdb |> 
  xml2::read_html() |> 
  xml2::xml_find_all("//pre//a") |> 
  xml2::xml_attr("href") |> str_remove_all(pattern = "/")

#buscando o release atual ----------
current_release <- "https://tritrypdb.org/common/downloads/Current_Release/TcruziCLBrenerEsmeraldo-like/fasta/data/"
r_current <- httr::GET(current_release)

version <- r_current |> 
  xml2::read_html() |> 
  xml2::xml_find_all("//a") |> 
  xml2::xml_attr("href") |> 
  stringr::str_extract("[^_]+_[^_]+") |> 
  stringr::str_remove("TcruziCLBrenerEsmeraldo-like")

current <- version[9]  

#nomes necessários para gerar os links da tabela final -------
current_release <- "https://tritrypdb.org/common/downloads/Current_Release/"
CDS <- "_AnnotatedCDSs.fasta"
protein <- "_AnnotatedProteins.fasta"
transcripts <- "_AnnotatedTranscripts.fasta"
genome <- "_Genome.fasta "

links_temp <- paste0(current_release, names)

all <- c(CDS, protein, transcripts, genome)
#gerando a tabela final -----------

tables <- list()
for (i in all) {
  link <- paste0(links_temp, "/fasta", "/data/", current, names, i) |> 
    as.data.frame()
  
  colnames(link) <- "link"
  
  char <- 1:10 |> as.character()
  
  link_final <- link |> mutate(test = link, type = i, release = current) |> 
    separate(test, into = char, sep = "/") |> select("7", type, release, "3", link) |> 
    rename(species = "7", database = "3") |> 
    mutate(type = str_remove(string = type, pattern = "_"))
  
  link_final <- link_final |> filter(!str_detect(species, "="),
                                     (!str_detect(species, "commondownloads")),
                                     (!str_detect(species, "Build_number")))
  tables[[i]] <- link_final
}

data.table::rbindlist(tables) |> arrange(species) |> readr::write_csv("tritrypDT.csv")
