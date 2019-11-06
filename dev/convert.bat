cd "C:\Program Files\THQ\Gas Powered Games\Supreme Commander\maps\supremeRiskW"
convert supremeRisk_hm2.png -filter Cubic -resize 1025x1025 -depth 16 -endian LSB -blur 10 -modulate 2.1 rc15.gray
copy rc15.gray rc001.raw