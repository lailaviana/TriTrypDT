
# TriTrypDT

TriTrypDT trata-se de uma tabela contendo todos os links para os fastas
disponíveis no TriTrypDB na sua versão mais atual. Para baixar o arquivo
de interesse basta localizá-lo na tabela, e juntamente com o comando
`wget` baixar no seu servidor de trabalho.

``` r
readr::read_csv("tritrypDT.csv", show_col_types = FALSE) |> 
  knitr::kable()
```

