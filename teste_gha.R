#pacotes ------------
library(dplyr)
library(purrr)
library(stringr)
library(httr)
library(RSelenium)
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
system("docker pull selenium/standalone-chrome", wait=TRUE)
Sys.sleep(5)
system("docker run -d -p 4445:4444 selenium/standalone-chrome", wait=TRUE)
Sys.sleep(5)

remDr <- remoteDriver("localhost", 4445L, "chrome")
remDr$open()
remDr$navigate("https://tritrypdb.org/tritrypdb/app/")
release <- remDr$findElements("xpath", "//*[@class='vpdb-HeaderBrandingSuperscript']")

release <- release |>
  purrr::map(\(x) x$getElementText()) |>
  purrr::map_chr(1) |> stringr::str_squish() 
release <- release |> stringr::str_replace("Release ", "TriTrypDB-")

ses$quit()
rm(ses)

current <- release |> stringr::str_extract("^(.*? )") |> stringr::str_replace(" ", "_" )
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


