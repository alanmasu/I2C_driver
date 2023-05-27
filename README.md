# Driver $I^2C$

Il top level di questo progetto è l'entità "I2C_temp_sensor_controller" che contiene al suo interno:
1. una macchina a stati che controlla il sensore di temperatura, copiata pari pari da Mendicino; 
2. il driver $I^2C$
3. il driver $SPI$ per il display OLED
   
I dati li ho plottati sul display per intero in HEX format, mentre sui LED ho plottato solo gli 8 bit piu significativi;

In teoria dovrebbe fare un aggiornamento ogni secondo, secondo me non lo fa correttamente!

# Problemi 
Attaccando l'oscilloscopio noto che SDA è sempre allo '0' logico, ma da simulazione funziona tutto correttamente! 
Spero si capisca come ho struttarato il codice e la macchina a stati del driver.