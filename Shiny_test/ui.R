#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

shinyUI(
  fluidPage(
    tags$head(
      tags$style(HTML("
                      @import url('//fonts.googleapis.com/css?family=IBM+Plex+Sans&display=swap');
                      "))
    ),
    titlePanel(title=div(h1("Modelo de Riesgo-SESA", 
                            style = "font-family: 'IBM Plex Sans', bold;font-weight: 300; line-height: 1.1;color: #084fc9;"), 
                         img(src="https://grupomancheno.com/wp/wp-content/uploads/2017/04/logo-equinoccial.png", 
                             height = 75, 
                             width = 121,
                             style="position:absolute;right:15px;z-index:100000;"))),
    navbarPage("Paneles de Control",
               tabPanel("Home",
                        # adding the new div tag to the sidebar            
                        tags$div(class="header", checked=NA,
                                 p("Bienvenido a los Paneles de Control. ", 
                                   style = "font-family: 'IBM Plex Sans', bold;font-weight: 300; line-height: 1.1;color: #0a0a0a;font-size: 35px;"),
                                 br(),
                                 p("Navegue por las pestañas para controlar los datos de entrada y salida del modelo.",
                                   style = "font-family: 'IBM Plex Sans', bold;font-weight: 300; line-height: 1.1;color: #0a0a0a;font-size: 20px;"),
                                 br(),
                                 p("Esta aplicación fue diseñada con Shiny de Rstudio."),
                                 tags$a(href="shiny.rstudio.com/tutorial", "Click Here!")
                        )
               ),
               tabPanel("Datos de Entrada al Modelo",
                        sidebarLayout(
                          sidebarPanel(verticalLayout(h1("Filtros:"),
                                                      numericInput(inputId = "IN_Percentiles",
                                                                   label = "Diferencia Absoluta Percentiles", 
                                                                   value = 0.05, 
                                                                   step = 0.01
                                                      ),
                                                      numericInput(inputId = "IN_Totales",
                                                                   label = "Variación porcentual absoluta Totales (%)", 
                                                                   value = 10, 
                                                                   step = 1
                                                      ),
                                                      selectInput(inputId = "IN_Variables", 
                                                                  label = "Variables:", 
                                                                  choices = Lista_Variables
                                                      )
                          ), width = 2
                          ),
                          mainPanel(verticalLayout(h3('Alertas'),
                                                   h4("Variación de Percentiles: "),
                                                   span(textOutput(outputId = "OUT_TextoAlertasPercentiles"), style = "color:grey"),
                                                   h4("Variación de Totales: "),
                                                   span(textOutput(outputId = "OUT_TextoAlertasTotales"), style = "color:grey"),
                                                   splitLayout(verticalLayout(h3(textOutput(outputId = "OUT_TextoGrafPer")), #Poner El nombre de la variable 
                                                                              plotOutput(outputId = "OUT_PlotPercentiles"),
                                                                              h3(textOutput(outputId = "OUT_TextoTabTot")),
                                                                              dataTableOutput(outputId = "OUT_TableTotales")                           
                                                   ),
                                                   verticalLayout(
                                                     h3(textOutput(outputId = "OUT_TextoTabPer")),
                                                     dataTableOutput(outputId = "OUT_TablePercentiles")
                                                   )
                                                   )
                                    )
                          )
                        )                 
               ),
               navbarMenu("Datos de Salida del Modelo",
                          tabPanel("Estadísticos de variables", fluidRow(column(width = 3,DTOutput('estadisticos_t')))),
                          tabPanel("Semáforo para control de árboles", fluidRow(column(width = 3,DTOutput('semaforo_t'))))),
               
               navbarMenu("Análisis de Matices y Perfiles",
                          tabPanel("Estadísticos de variables", fluidRow(column(width = 3,DTOutput('matiz_t')))),
                          tabPanel("Semáforo Matices", fluidRow(column(width = 3,DTOutput('semf_matiz_t'))))),
               
               tabPanel("Sábana de datos",
                        fluidRow(column(width = 3,DTOutput('sabana_t')),
                                 column(4, downloadButton("downloadData", "Descargar sábana de datos")))
                        
               )
    )
  )
)
