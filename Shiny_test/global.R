#Aquí escribir el código para acceder directamente al Central Bucket
library(readr)
library(dplyr)
library(DT)
library(stringr)

library(shiny)
library(ggplot2)
library(tibble)
library(tidyverse)
periodo <- "2019-01_2019_09"
######################## PANEL DE ENTRADA ########################
Percentiles <- read_csv("~/Shiny_test/Input_Files/PCEntrada_Percentiles.csv") 
Percentiles2 <- Percentiles
Percentiles <- Percentiles[, c('Nombre_Fuente', 'Percentil', 'Periodo','Value')]
Percentiles$Percentil <- sprintf("%0.2f", Percentiles$Percentil) 
Percentiles <- Percentiles %>% 
  group_by(Periodo, Nombre_Fuente) %>%
  mutate(grouped_id = row_number())
Percentiles <- spread(Percentiles, key=Periodo, value=Value)
Percentiles["Diferencia Absoluta"] <- abs(Percentiles$Modelo - Percentiles$`2019-11`)


Totales <- read_csv("~/Shiny_test/Input_Files/PCEntrada_Medidas.csv") 
Totales <- Totales[, c('Nombre_Fuente', 'Medida', 'Periodo','Valor')]
Totales <- Totales %>% 
  group_by(Periodo,  Medida) %>% 
  mutate(grouped_id = row_number())

Totales <- spread(Totales, key=Periodo, value=Valor)
Totales["Variacion porcentual Absoluta"] = abs((Totales$`2019-11` - Totales$Modelo )*100/Totales$Modelo)
Totales$`Variacion porcentual Absoluta`[is.nan(Totales$`Variacion porcentual Absoluta`)]<- 0

Lista_Variables <- unique(Percentiles$Nombre_Fuente)
Lista_Periodos <- unique(Percentiles$Periodo)

######################## PANEL DE SALIDA ########################
#Aquí hay que cambiar la dataframe "df_TSC" por la sábana final de datos y la "df_mat" ya no sería necesaria

df_TSC <- read_csv("~/Shiny_test/Input_Files/Datos_Clusterizacion_1_3_Niveles.csv")
df_mat <- read_csv("~/Shiny_test/Input_Files/Matices_Cruzar_DF.csv")

#variables resultantes de los árboles a ser controladas
var_ps <- c("DeviceId", "Cluster_N3_Descriptivo", #identificadores de dispositivo
            'PCT_Guayas_y_alr_dist',              #Geográficas
            'PCT_Pich_y_alr_dist',                #Geográficas
            
            'PRCNTIL_POS_Pich_y_alr_dur',         #Geográficas
            
            'PRCNTIL_POS_Duration_h',             #Uso
            'PRCNTIL_POS_Count_Dist_Date',        #Uso
            'PRCNTIL_POS_Viajes_dia',             #Uso
            
            'PRCNTIL_POS_DT_Weekday_dur',         #Día de la semana
            'PRCNTIL_POS_N_Trips_DT_Weekday',     #Día de la semana
            'PRCNTIL_POS_N_Trips_DT_Weekend',     #Día de la semana
            'PRCNTIL_POS_DT_Weekend_dist',        #Día de la semana
            'PRCNTIL_POS_DT_Weekend_dur',
            
            'PRCNTIL_POS_DayTime_0_6_dur',        #Rangos horarios
            'PRCNTIL_POS_N_Trips_DayTime_6_9',    #Rangos horarios
            'PRCNTIL_POS_N_Trips_DayTime_18_21',  #Rangos horarios
            'PRCNTIL_POS_DayTime_18_21_dur',      #Rangos horarios
            'PRCNTIL_POS_DayTime_21_24_dur',      #Rangos horarios
            'PRCNTIL_POS_N_Trips_DayTime_21_24',  #Rangos horarios
            
            'PRCNTIL_POS_Dur_50_h',               #Tipo de via
            'PRCNTIL_POS_Dur_100_h',              #Tipo de via
            'PRCNTIL_POS_Dur_70_h',               #Tipo de via
            
            
            'PRCNTIL_POS_N_Trips_Tipo_Viaje_A',   #Tipo de viajes
            'PRCNTIL_POS_Tipo_Viaje_A_dur',       #Tipo de viajes
            'PRCNTIL_POS_N_Trips_Tipo_Viaje_B',   #Tipo de viajes
            'PRCNTIL_POS_Tipo_Viaje_B_dur',       #Tipo de viajes
            'PCT_Tipo_Viaje_C_dur',               #Tipo de viaje
            'PRCNTIL_POS_Tipo_Viaje_C_dur',       #Tipo de viajes
            'PRCNTIL_POS_Tipo_Viaje_D_dur'        #Tipo de viajes
)
df_var_ps <- df_TSC[var_ps]
df_p50 = data.frame()
df_p50 = df_var_ps[c("DeviceId", "Cluster_N3_Descriptivo")]

#Añadir banderas 
for(col in var_ps[3:length(var_ps)]){
  
  if(grepl("PCT", col)){
    name <- paste(str_remove(col,"PCT_"),"%_bnd", sep = "_")
    q = quantile(df_var_ps[[col]], c(0.25,0.5,0.75)) 
    df_p50[[name]] <- ifelse(df_var_ps[[col]]<q[1], "D", ifelse((df_var_ps[[col]]>=q[1])&(df_var_ps[[col]]<q[2]), "C", ifelse((df_var_ps[[col]]>=q[2])&(df_var_ps[[col]]<q[3]), "B", "A"))) 
  }
  else{
    name <- paste(str_remove(col,"PRCNTIL_POS_"),"bnd", sep = "_")
    df_p50[[name]] <- ifelse(df_var_ps[[col]]<0.25, "D", ifelse((df_var_ps[[col]]>=0.25)&(df_var_ps[[col]]<0.5), "C", ifelse((df_var_ps[[col]]>=0.5)&(df_var_ps[[col]]<0.75), "B", "A")))
  }
}
# Calcular validador
df_p50$Validador <- apply(df_p50[, c(3:length(colnames(df_p50)))],1, paste , collapse = "")
df_var_ps$Validador <- df_p50$Validador #para calcular los estadísticos por grupo: mínimo, media, máximo


cluster_sizes <- df_TSC %>% group_by(Cluster_N3_Descriptivo) %>% summarise(Tam_Cluster = n())

#Calcular agregados
agg_p50 <- df_p50 %>%
  group_by(Cluster_N3_Descriptivo, Validador) %>%
  summarise(N_disp=n())

agg_p50 <- left_join(agg_p50, cluster_sizes, by="Cluster_N3_Descriptivo")
agg_p50$ConcentracionCluster <- agg_p50$N_disp/agg_p50$Tam_Cluster*100
agg_p50$ConcentracionGral <- agg_p50$N_disp/nrow(df_TSC)*100

#Semáforo
semaforo <- separate(data = agg_p50, col = Validador, into = colnames(df_p50)[3:29], sep = c(1:27))
semaforo$Validador <- agg_p50$Validador
var_semf <- c(colnames(agg_p50),colnames(df_p50)[3:29])
semaforo <- semaforo[var_semf]

agg_estad <- df_var_ps[c(2:ncol(df_var_ps))] %>% group_by(Cluster_N3_Descriptivo, Validador) %>%
  summarise_all(funs(min, mean, max))

df_agg_todo <- left_join(agg_p50, agg_estad, by= c("Cluster_N3_Descriptivo","Validador"))



reordenar <- c(
  "Cluster_N3_Descriptivo","Validador","N_disp","Tam_Cluster","ConcentracionCluster","ConcentracionGral",
  "PCT_Guayas_y_alr_dist_min", "PCT_Guayas_y_alr_dist_mean", "PCT_Guayas_y_alr_dist_max",
  "PCT_Pich_y_alr_dist_min", "PCT_Pich_y_alr_dist_mean","PCT_Pich_y_alr_dist_max", 
  "PRCNTIL_POS_Pich_y_alr_dur_min", "PRCNTIL_POS_Pich_y_alr_dur_mean","PRCNTIL_POS_Pich_y_alr_dur_max", 
  "PRCNTIL_POS_Duration_h_min", "PRCNTIL_POS_Duration_h_mean","PRCNTIL_POS_Duration_h_max",
  "PRCNTIL_POS_Count_Dist_Date_min","PRCNTIL_POS_Count_Dist_Date_mean","PRCNTIL_POS_Count_Dist_Date_max",
  "PRCNTIL_POS_Viajes_dia_min","PRCNTIL_POS_Viajes_dia_mean","PRCNTIL_POS_Viajes_dia_max",
  "PRCNTIL_POS_DT_Weekday_dur_min","PRCNTIL_POS_DT_Weekday_dur_mean","PRCNTIL_POS_DT_Weekday_dur_max",
  "PRCNTIL_POS_N_Trips_DT_Weekday_min","PRCNTIL_POS_N_Trips_DT_Weekday_mean","PRCNTIL_POS_N_Trips_DT_Weekday_max",
  "PRCNTIL_POS_N_Trips_DT_Weekend_min","PRCNTIL_POS_N_Trips_DT_Weekend_mean","PRCNTIL_POS_N_Trips_DT_Weekend_max",
  "PRCNTIL_POS_DT_Weekend_dist_min","PRCNTIL_POS_DT_Weekend_dist_mean","PRCNTIL_POS_DT_Weekend_dist_max",        
  "PRCNTIL_POS_DT_Weekend_dur_min", "PRCNTIL_POS_DT_Weekend_dur_mean","PRCNTIL_POS_DT_Weekend_dur_max",         
  "PRCNTIL_POS_DayTime_0_6_dur_min", "PRCNTIL_POS_DayTime_0_6_dur_mean","PRCNTIL_POS_DayTime_0_6_dur_max",
  "PRCNTIL_POS_N_Trips_DayTime_6_9_min","PRCNTIL_POS_N_Trips_DayTime_6_9_mean","PRCNTIL_POS_N_Trips_DayTime_6_9_max",    
  "PRCNTIL_POS_N_Trips_DayTime_18_21_min","PRCNTIL_POS_N_Trips_DayTime_18_21_mean","PRCNTIL_POS_N_Trips_DayTime_18_21_max",  
  "PRCNTIL_POS_DayTime_18_21_dur_min","PRCNTIL_POS_DayTime_18_21_dur_mean","PRCNTIL_POS_DayTime_18_21_dur_max",
  "PRCNTIL_POS_DayTime_21_24_dur_min","PRCNTIL_POS_DayTime_21_24_dur_mean","PRCNTIL_POS_DayTime_21_24_dur_max",      
  "PRCNTIL_POS_N_Trips_DayTime_21_24_min","PRCNTIL_POS_N_Trips_DayTime_21_24_mean","PRCNTIL_POS_N_Trips_DayTime_21_24_max",
  "PRCNTIL_POS_Dur_50_h_min", "PRCNTIL_POS_Dur_50_h_mean", "PRCNTIL_POS_Dur_50_h_max",
  "PRCNTIL_POS_Dur_100_h_min", "PRCNTIL_POS_Dur_100_h_mean", "PRCNTIL_POS_Dur_100_h_max",
  "PRCNTIL_POS_Dur_70_h_min", "PRCNTIL_POS_Dur_70_h_mean","PRCNTIL_POS_Dur_70_h_max", 
  "PRCNTIL_POS_N_Trips_Tipo_Viaje_A_min", "PRCNTIL_POS_N_Trips_Tipo_Viaje_A_mean", "PRCNTIL_POS_N_Trips_Tipo_Viaje_A_max",
  "PRCNTIL_POS_Tipo_Viaje_A_dur_min", "PRCNTIL_POS_Tipo_Viaje_A_dur_mean","PRCNTIL_POS_Tipo_Viaje_A_dur_max",
  "PRCNTIL_POS_N_Trips_Tipo_Viaje_B_min","PRCNTIL_POS_N_Trips_Tipo_Viaje_B_mean","PRCNTIL_POS_N_Trips_Tipo_Viaje_B_max",
  "PRCNTIL_POS_Tipo_Viaje_B_dur_min","PRCNTIL_POS_Tipo_Viaje_B_dur_mean","PRCNTIL_POS_Tipo_Viaje_B_dur_max",
  "PCT_Tipo_Viaje_C_dur_min","PCT_Tipo_Viaje_C_dur_mean","PCT_Tipo_Viaje_C_dur_max", 
  "PRCNTIL_POS_Tipo_Viaje_C_dur_min","PRCNTIL_POS_Tipo_Viaje_C_dur_mean", "PRCNTIL_POS_Tipo_Viaje_C_dur_max",
  "PRCNTIL_POS_Tipo_Viaje_D_dur_min","PRCNTIL_POS_Tipo_Viaje_D_dur_mean","PRCNTIL_POS_Tipo_Viaje_D_dur_max"
)

df_agg_todo <- df_agg_todo[reordenar]

#Cambiar las líneas de código siguientes para que use directamente 
#la sábana de datos con los matices
#Cruzar con datos de matices

df_var_mat <- df_TSC[c("DeviceId", "Cluster_N3_Descriptivo", "PRCNTIL_POS_Guayas_y_alr_dur","PRCNTIL_POS_Pich_y_alr_dur", "PRCNTIL_POS_Otras_dur",
                       "PRCNTIL_POS_Duration_h","PRCNTIL_POS_DayTime_0_6_dur","PRCNTIL_POS_DayTime_6_9_dur",
                       "PRCNTIL_POS_DayTime_9_18_dur","PRCNTIL_POS_DayTime_18_21_dur","PRCNTIL_POS_DayTime_21_24_dur",
                       "PRCNTIL_POS_Dur_90_h","PRCNTIL_POS_Dur_100_h",
                       "PRCNTIL_POS_Tipo_Viaje_C_dur","PRCNTIL_POS_Tipo_Viaje_D_dur")]
var_mat <- c("PRCNTIL_POS_Guayas_y_alr_dur","PRCNTIL_POS_Pich_y_alr_dur", "PRCNTIL_POS_Otras_dur",
             "PRCNTIL_POS_Duration_h","PRCNTIL_POS_DayTime_0_6_dur","PRCNTIL_POS_DayTime_6_9_dur",
             "PRCNTIL_POS_DayTime_9_18_dur","PRCNTIL_POS_DayTime_18_21_dur","PRCNTIL_POS_DayTime_21_24_dur",
             "PRCNTIL_POS_Dur_90_h","PRCNTIL_POS_Dur_100_h",
             "PRCNTIL_POS_Tipo_Viaje_C_dur","PRCNTIL_POS_Tipo_Viaje_D_dur")
#Añadir banderas 
for(col in var_mat){
  name <- paste(str_remove(col,"PRCNTIL_POS_"),"bnd", sep = "_")
    df_var_mat[[name]] <- ifelse(df_var_mat[[col]]<0.25, "D", 
                                 ifelse((df_var_mat[[col]]>=0.25)&(df_var_mat[[col]]<0.5), "C", 
                                        ifelse((df_var_mat[[col]]>=0.5)&(df_var_mat[[col]]<0.75), "B", "A")))
}

df_var_mat$Validador <- apply(df_var_mat[, c((length(var_mat)+3):length(df_var_mat))],1, paste , collapse = "")

dev_facts_mat <- left_join(df_var_mat,df_mat[c("Cluster_N3_Descriptivo","Validador", "Perfil","Grupo_Perfil")], by = c("Cluster_N3_Descriptivo", "Validador"))
dev_facts_mat[is.na(dev_facts_mat)] <- "Otros"

#apply(is.na(dev_facts_mat), 2, sum)

#Semáforo para los matices
#Calcular agregados
agg_mat <- dev_facts_mat %>%
  group_by(Cluster_N3_Descriptivo, Validador, Perfil, Grupo_Perfil) %>%
  summarise(N_disp=n())

agg_mat <- left_join(agg_mat, cluster_sizes, by="Cluster_N3_Descriptivo")
agg_mat$ConcentracionCluster <- agg_mat$N_disp/agg_mat$Tam_Cluster*100
agg_mat$ConcentracionGral <- agg_mat$N_disp/nrow(df_TSC)*100

#Semáforo
var_mat_banderas <- colnames(dev_facts_mat)[16:28]
semaforo_mat <- separate(data = agg_mat, col = Validador, into = var_mat_banderas, sep = c(1:length(var_mat)))
semaforo_mat$Validador <- agg_mat$Validador
var_semf_mat <- c(colnames(agg_mat),var_mat_banderas)
semaforo_mat <- semaforo_mat[var_semf_mat]

#Estadísticos
agg_mat_estd <- dev_facts_mat[,c('Cluster_N3_Descriptivo', 'Validador', 'Perfil', 'Grupo_Perfil', var_mat)] %>% group_by(Cluster_N3_Descriptivo, Validador, Perfil, Grupo_Perfil) %>%
  summarise_all(funs(min, mean, max))

df_agg_mat_todo <- left_join(agg_mat, agg_mat_estd, by= c('Cluster_N3_Descriptivo', 'Validador', 'Perfil', 'Grupo_Perfil'))
df_agg_mat_todo <- df_agg_mat_todo[c("Cluster_N3_Descriptivo","Validador","Perfil",
                               "Grupo_Perfil","N_disp","Tam_Cluster",
                               "ConcentracionCluster","ConcentracionGral",
                               "PRCNTIL_POS_Guayas_y_alr_dur_min","PRCNTIL_POS_Guayas_y_alr_dur_mean","PRCNTIL_POS_Guayas_y_alr_dur_max",
                               "PRCNTIL_POS_Pich_y_alr_dur_min","PRCNTIL_POS_Pich_y_alr_dur_mean","PRCNTIL_POS_Pich_y_alr_dur_max",
                               "PRCNTIL_POS_Otras_dur_min","PRCNTIL_POS_Otras_dur_mean","PRCNTIL_POS_Otras_dur_max",
                               "PRCNTIL_POS_Duration_h_min","PRCNTIL_POS_Duration_h_mean","PRCNTIL_POS_Duration_h_max",
                               "PRCNTIL_POS_DayTime_0_6_dur_min","PRCNTIL_POS_DayTime_0_6_dur_mean","PRCNTIL_POS_DayTime_0_6_dur_max",
                               "PRCNTIL_POS_DayTime_6_9_dur_min","PRCNTIL_POS_DayTime_6_9_dur_mean","PRCNTIL_POS_DayTime_6_9_dur_max",
                               "PRCNTIL_POS_DayTime_9_18_dur_min","PRCNTIL_POS_DayTime_9_18_dur_mean","PRCNTIL_POS_DayTime_9_18_dur_max",
                               "PRCNTIL_POS_DayTime_18_21_dur_min","PRCNTIL_POS_DayTime_18_21_dur_mean","PRCNTIL_POS_DayTime_18_21_dur_max",
                               "PRCNTIL_POS_DayTime_21_24_dur_min","PRCNTIL_POS_DayTime_21_24_dur_mean","PRCNTIL_POS_DayTime_21_24_dur_max",
                               "PRCNTIL_POS_Dur_90_h_min","PRCNTIL_POS_Dur_90_h_mean", "PRCNTIL_POS_Dur_90_h_max",
                               "PRCNTIL_POS_Dur_100_h_min","PRCNTIL_POS_Dur_100_h_mean","PRCNTIL_POS_Dur_100_h_max",
                               "PRCNTIL_POS_Tipo_Viaje_C_dur_min","PRCNTIL_POS_Tipo_Viaje_C_dur_mean","PRCNTIL_POS_Tipo_Viaje_C_dur_max",
                               "PRCNTIL_POS_Tipo_Viaje_D_dur_min","PRCNTIL_POS_Tipo_Viaje_D_dur_mean","PRCNTIL_POS_Tipo_Viaje_D_dur_max")]

# SÁBANA DE DATOS A DESCARGAR

sabana_datos <- left_join(df_TSC, dev_facts_mat[c("DeviceId",
                                                  "Guayas_y_alr_dur_bnd","Pich_y_alr_dur_bnd","Otras_dur_bnd",
                                                  "Duration_h_bnd","DayTime_0_6_dur_bnd", "DayTime_6_9_dur_bnd","DayTime_9_18_dur_bnd",
                                                  "DayTime_18_21_dur_bnd","DayTime_21_24_dur_bnd", "Dur_90_h_bnd", 
                                                  "Dur_100_h_bnd","Tipo_Viaje_C_dur_bnd","Tipo_Viaje_D_dur_bnd",
                                                  "Validador","Perfil","Grupo_Perfil")], by="DeviceId")
