#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

shinyServer(function(input, output) {
    
###################### PANEL DATOS ENTRADA ##########################
      
  output$OUT_TextoAlertasPercentiles <- renderText({
    # Percentiles 
    ListaPercentiles <- Percentiles$Nombre_Fuente[Percentiles$`Diferencia Absoluta` >= input$IN_Percentiles]
    ListaPercentiles <- ListaPercentiles[!duplicated(ListaPercentiles)]
    if(length(ListaPercentiles)>0){
      Texto_Percentiles <- paste(ListaPercentiles, collapse=", ")
      print(Texto_Percentiles)
    }else {
      print("No existen Alertas")
    }
    
  })
  
  output$OUT_TextoAlertasTotales <- renderText({
    # Totales
    ListaTotales <- Totales$Nombre_Fuente[Totales$`Variacion porcentual Absoluta` >= input$IN_Totales]
    ListaTotales <- ListaTotales[!duplicated(ListaTotales)]
    if(length(ListaTotales)>0){
      ListaTotales <- paste(ListaTotales, collapse=", ")
      print(ListaTotales)
    }else{
      print("No existen Alertas")
    }
  }
  )
  output$OUT_TextoGrafPer <- renderText({
    print(paste0("Gráfico de Percentiles de ",input$IN_Variables))
  })
  output$OUT_TextoTabPer <- renderText({
    print(paste0("Percentiles de ",input$IN_Variables))
  })
  output$OUT_TextoTabTot <- renderText({
    print(paste0("Totales de ",input$IN_Variables))
  })
  output$OUT_PlotPercentiles <- renderPlot({
    Percentiles2 <- Percentiles2[Percentiles2$Nombre_Fuente == input$IN_Variables, c('Percentil', 'Periodo','Value')]
    ggplot( data = Percentiles2, 
            mapping = aes(x=Percentil, 
                          y=Value, 
                          color = Periodo))+
              geom_line()+
              geom_point()
  }
  )
  output$OUT_TablePercentiles <- renderDataTable({
    Percentiles <- Percentiles[Percentiles$Nombre_Fuente == input$IN_Variables, c('Percentil', 'Modelo','2019-11',"Diferencia Absoluta")]
    datatable(Percentiles, options = list("pageLength" = 25)) %>% formatStyle(columns = "Diferencia Absoluta", target = "row", 
                                           backgroundColor = styleInterval(input$IN_Percentiles, c("#d5edd0","#F7080880"))
                                           ) 
  }
  )
  output$OUT_TableTotales <- renderDataTable({
    Totales <- Totales[Totales$Nombre_Fuente == input$IN_Variables, c('Medida','Modelo')]
    ###### DESCOMENTAR PARA USO DE COLORES
    #Totales <- Totales[Totales$Nombre_Fuente == input$IN_Variables, c('Medida','Modelo','2019-11',"Variacion porcentual Absoluta")]
    #datatable(Totales) %>% formatStyle(columns = "Variacion porcentual Absoluta", target = "row", 
    #                                       backgroundColor = styleInterval(input$IN_Totales, c("#d5edd0","#F7080880"))) %>% formatRound(c('Modelo','2019-11','Variacion porcentual Absoluta'), 3) 
  }
  )

    
###################### PANEL DATOS SALIDA ##########################   
    #Desplegar el semáforo de control de los árboles
     output$semaforo_t <- renderDT(
       datatable(semaforo, filter = 'top')%>%
                 formatStyle(
                   colnames(df_p50)[3:29],
                     backgroundColor = styleEqual(
                         c("A", "B", "C", "D"), c('#ffc7cd', '#ffbf90', '#ffec9d', '#c6efcd')
                         )
                     )
     )
     #Estadísticos de variables que salen en los árboles
     output$estadisticos_t <- renderDT(
       datatable(df_agg_todo, filter = 'top'))
     
     # MATICES estadísticos
     output$matiz_t <- renderDT(
       datatable(df_agg_mat_todo, filter = 'top'))
     # MATICES semáforo
     output$semf_matiz_t <- renderDT(
       datatable(semaforo_mat, filter = 'top')%>%
         formatStyle(var_mat_banderas,
           backgroundColor = styleEqual(
             c("A", "B", "C", "D"), c('#ffc7cd', '#ffbf90', '#ffec9d', '#c6efcd')
           )
       )
     )
     #Mostrar sábana de datos
     output$sabana_t <- renderDT(
         datatable(sabana_datos, filter = 'top')
     )
     #Descargar sábana de datos
     output$downloadData <- downloadHandler(
         filename = function() {
             paste("SabanaDatos_",periodo, ".csv", sep = "")
         },
         content = function(file) {
             write.csv(sabana_datos, file, row.names = FALSE)
         }
     )
})
