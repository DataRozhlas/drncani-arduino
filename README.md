# Kvalita povrchu D1

Zatím nevydáno

### Data

Naměřená data jsou v `data-dobrna.7z` a `data-doprahy.7z`, v každém archivu pak jsou následující soubory:

* `[timestamp]-COM3.csv` - záznam z levého kola
* `[timestamp]-COM6.csv` - záznam z pravého kola
* `[timestamp]-COM5-GPS.csv` - záznam z GPS

Záznamy z kol jsou v CSV (s nejstejným počtem záznamů na řádek). Každý řádek značí jednu přijatou dávku hodnot z měřícího zařízení a je uvozen timestampem. Možné hodnoty jsou od -32 768 do 32 767, stupnice je od -16g do +16g. 1g by tak mělo odpovídat hodnotě 2048, ve skutečnosti však snímače nebyly nainstalovány perfektně kolmo a 1g je kolem 1900 (je to vidět při začátku a konci měření, kdy se snímače nepohybovaly). Perioda měření byla 1000 Hz.

GPS soubor má analogický formát s měřeními akcelerometru, na každém řádku je jedna přijatá dávka ze sériového portu, uvozená timestampem. Dávka byla na straně GPS omezená délkou, takže docházelo k rozdělení NMEA vět do více dávek, před zpracováním je tak nutné jednotivé věty opět pospojovat. Perioda měření byla 10 Hz.

Všechny timestampy jsou javascriptově milisekundové od 1. 1. 1970. Jejich zdroj jsou interní hodiny PC, nejsou tedy synchronní s UTC časem přijatým z GPS. Všechny timestampy jsou ale z jednoho zdroje a tedy synchronní vůči sobě navzájem.

Odpověď na otázku "kde to drncá" tedy lze nalézt časovou synchronizací záznamů z GPS a z akcelerometrů. K tomu slouží následující soubory:

* `gpsCleaner.ls` - zkombinuje "roztrané" NMEA věty do formátu 1 věta = 1 řádek
* `parseNmea2.ls` - převede NMEA zprávy na CSV jednotlivých fixů, včetně jejich "doby platnosti", tedy od kdy do kdy bylo auto na daném místě (pokud nedošlo k výpadkům příjmu, je doba platnosti 100 ms).
* `CombineGpsAndAccel.ls` - zkombinuje fixy z GPS a data z akcelerometru do jednoho souboru. Ke každému fixu může dát statistické informace o naměřených hodnotách - maximum, minimum, průměr, medián, rozptyl apod.

Soubory `*.bin` jsou raw data tak, jak je Arduina/GPS vysílaly. Ukládaly se jako záloha, kdyby v processingu byla chyba. Nakonec nebyly potřeba.

### Technika

Na náprávách seděla Arduina Pro Mini, v autě bylo Nano a Mega. Mezi sebou komunikovaly bezdrátově přes Nordic Semiconductor NRF24L01. Použité akcelerometry byly InvenSense MPU-6050.

GPS modul byl použit uBlox MAX-7C, připojený přes UART-USB převodník přímo do PC.

> Projekt [datové rubriky Českého rozhlasu](http://www.rozhlas.cz/zpravy/data/). Uvolněno pod licencí [CC BY-NC-SA 3.0 CZ](http://creativecommons.org/licenses/by-nc-sa/3.0/cz/), tedy uveďte autora, nevyužívejte dílo ani přidružená data komerčně a zachovejte licenci.
