// Stile scuro delle mappe Google dell'app (prima solo nella mappa della
// destinazione, spostato qui senza cambiamenti per usarlo anche in Mappa e
// Itinerario).

const String amaterasuDarkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#17120f"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#b7a99b"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#100c0a"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#4a3329"}]
  },
  {
    "featureType": "administrative.country",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#6b4536"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#18120f"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#211713"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9c7c68"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#33231d"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#241915"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#5a3427"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#7d4430"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2a1d18"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#090b0d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#66584f"}]
  }
]
''';
