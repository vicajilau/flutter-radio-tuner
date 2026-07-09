// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get searchPlaceholder => 'Buscar emisoras, géneros, etiquetas...';

  @override
  String get popularGenres => 'Géneros populares';

  @override
  String get favoriteStations => 'Emisoras favoritas';

  @override
  String get recentlyPlayed => 'Escuchadas recientemente';

  @override
  String get recommendedStations => 'Emisoras recomendadas';

  @override
  String get searchResults => 'Resultados de búsqueda';

  @override
  String get selectGenreToExplore =>
      'Selecciona un género para empezar a explorar';

  @override
  String get noFavoritesYet => 'Aún no hay emisoras favoritas';

  @override
  String get favoritesSubtitle => 'Tus emisoras favoritas aparecerán aquí';

  @override
  String get noRecentlyPlayed => 'No hay emisoras escuchadas recientemente';

  @override
  String get recentlyPlayedSubtitle =>
      'Las emisoras que escuches aparecerán aquí';

  @override
  String get noRecommended => 'No hay emisoras recomendadas';

  @override
  String get recommendedSubtitle => 'Vuelve más tarde para ver recomendaciones';

  @override
  String get nowStreaming => 'TRANSMITIENDO AHORA';

  @override
  String get noStationSelected => 'Ninguna emisora seleccionada.';

  @override
  String sleepIn(String time) {
    return 'Apagar en $time';
  }

  @override
  String get noWebsite => 'No hay sitio web disponible para esta emisora.';

  @override
  String get invalidWebsite => 'URL del sitio web de la emisora inválida.';

  @override
  String couldNotOpen(String url) {
    return 'No se pudo abrir: $url';
  }

  @override
  String get clearSearchAndFilters => 'Limpiar búsqueda y filtros';

  @override
  String noStationsFoundForQuery(String query) {
    return 'No se encontraron emisoras que coincidan con \"$query\"';
  }

  @override
  String noStationsFoundForCategory(String tag) {
    return 'No se encontraron emisoras en la categoría \"$tag\"';
  }

  @override
  String get noStationsFoundForFilters =>
      'No se encontraron emisoras que coincidan con los filtros actuales';

  @override
  String get sleepTimer => 'TEMPORIZADOR';

  @override
  String get sleepTimerSubtitle =>
      'Detener reproducción automáticamente tras transcurrir el tiempo';

  @override
  String get cancel => 'Cancelar';

  @override
  String get connecting => 'Conectando...';

  @override
  String get buffering => 'Búfer...';

  @override
  String get playingLive => 'Transmitiendo en vivo';

  @override
  String get paused => 'Pausado';

  @override
  String get bufferingStream => 'Búfer de transmisión...';

  @override
  String get resolvingNodes => 'Resolviendo nodos de radio...';

  @override
  String get connectionError => 'Error de conexión';

  @override
  String get noStationsFound => 'No se encontraron emisoras';

  @override
  String get searchEmptySubtitle =>
      'Intenta buscar un nombre, género o etiqueta diferente.';

  @override
  String get noStationsAvailable =>
      'No hay emisoras disponibles en este momento.';

  @override
  String get retryConnection => 'Reintentar conexión';

  @override
  String get reset => 'Restablecer';

  @override
  String get appTagline =>
      'S I N T O N I Z A D O R   D E   R A D I O   P R E M I U M';

  @override
  String get streamWorldsMusic => 'Escucha la música del mundo';

  @override
  String get appTitle => 'Sintonizador de Radio';

  @override
  String get noInternet => 'Sin conexión a internet';

  @override
  String get reconnecting => 'Reconectando...';

  @override
  String get streamOffline =>
      'No se puede reproducir esta emisora. La transmisión podría estar fuera de línea.';
}
