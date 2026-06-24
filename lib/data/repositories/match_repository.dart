import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match_model.dart';
import '../../core/services/storage_service.dart';
import 'initial_schedule.dart';

class MatchGoals {
  final int minute;
  final String player;
  final bool isHome;
  final String detail;
  MatchGoals(this.minute, this.player, this.isHome, {this.detail = 'Goal!'});
}

class MatchRepository {
  // Dictionary of flag emojis for all 48 participating countries in WC 2026
  static const Map<String, String> teamFlags = {
    'mexico': '🇲🇽',
    'south africa': '🇿🇦',
    'south korea': '🇰🇷',
    'korea republic': '🇰🇷',
    'czechia': '🇨🇿',
    'czech republic': '🇨🇿',
    'canada': '🇨🇦',
    'bosnia & herzegovina': '🇧🇦',
    'bosnia and herzegovina': '🇧🇦',
    'qatar': '🇶🇦',
    'switzerland': '🇨🇭',
    'brazil': '🇧🇷',
    'morocco': '🇲🇦',
    'haiti': '🇭🇹',
    'scotland': '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
    'usa': '🇺🇸',
    'united states': '🇺🇸',
    'paraguay': '🇵🇾',
    'australia': '🇦🇺',
    'turkiye': '🇹🇷',
    'turkey': '🇹🇷',
    'germany': '🇩🇪',
    'curacao': '🇨🇼',
    'curaçao': '🇨🇼',
    'cote d\'ivoire': '🇨🇮',
    'ecuador': '🇪🇨',
    'netherlands': '🇳🇱',
    'japan': '🇯🇵',
    'sweden': '🇸🇪',
    'tunisia': '🇹🇳',
    'belgium': '🇧🇪',
    'egypt': '🇪🇬',
    'iran': '🇮🇷',
    'new zealand': '🇳🇿',
    'spain': '🇪🇸',
    'cabo verde': '🇨🇻',
    'saudi arabia': '🇸🇦',
    'uruguay': '🇺🇾',
    'france': '🇫🇷',
    'senegal': '🇸🇳',
    'iraq': '🇮🇶',
    'norway': '🇳🇴',
    'argentina': '🇦🇷',
    'algeria': '🇩🇿',
    'austria': '🇦🇹',
    'jordan': '🇯🇴',
    'portugal': '🇵🇹',
    'dr congo': '🇨🇩',
    'uzbekistan': '🇺🇿',
    'colombia': '🇨🇴',
    'england': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
    'croatia': '🇭🇷',
    'ghana': '🇬🇭',
    'panama': '🇵🇦',
    'ivory coast': '🇨🇮',
    'congo dr': '🇨🇩',
    'cape verde': '🇨🇻',
    'saudia arabia': '🇸🇦',
  };

  static String getFlag(String teamName) {
    return teamFlags[teamName.trim().toLowerCase()] ?? '🏳️';
  }

  static final Map<String, List<String>> _countryPlayers = {
    'mexico': ['Santiago Giménez', 'Hirving Lozano', 'Edson Álvarez', 'Luis Chávez', 'Orbelín Pineda', 'Henry Martín', 'Uriel Antuna', 'Jesús Gallardo'],
    'south africa': ['Percy Tau', 'Themba Zwane', 'Teboho Mokoena', 'Evidence Makgopa', 'Thapelo Morena', 'Aubrey Modiba', 'Mothobi Mvala', 'Ronwen Williams'],
    'south korea': ['Son Heung-Min', 'Hwang Hee-Chan', 'Lee Kang-In', 'Cho Gue-Sung', 'Hwang In-Beom', 'Kim Min-Jae', 'Lee Jae-Sung', 'Jeong Woo-Yeong'],
    'czech republic': ['Patrik Schick', 'Tomáš Souček', 'Adam Hložek', 'Alex Král', 'Ladislav Krejčí', 'Václav Černý', 'Jan Kuchta', 'Tomáš Holeš'],
    'czechia': ['Patrik Schick', 'Tomáš Souček', 'Adam Hložek', 'Alex Král', 'Ladislav Krejčí', 'Václav Černý', 'Jan Kuchta', 'Tomáš Holeš'],
    'canada': ['Alphonso Davies', 'Jonathan David', 'Cyle Larin', 'Tajon Buchanan', 'Stephen Eustáquio', 'Ismaël Koné', 'Alistair Johnston', 'Kamal Miller'],
    'bosnia & herzegovina': ['Edin Džeko', 'Miralem Pjanić', 'Sead Kolašinac', 'Ermedin Demirović', 'Rade Krunić', 'Amar Dedić', 'Benjamin Tahirović', 'Jovo Lukić'],
    'bosnia and herzegovina': ['Edin Džeko', 'Miralem Pjanić', 'Sead Kolašinac', 'Ermedin Demirović', 'Rade Krunić', 'Amar Dedić', 'Benjamin Tahirović', 'Jovo Lukić'],
    'qatar': ['Akram Afif', 'Almoez Ali', 'Hassan Al-Haydos', 'Boualem Khoukhi', 'Abdulaziz Hatem', 'Homam Ahmed', 'Lucas Mendes', 'Bassam Al-Rawi'],
    'switzerland': ['Granit Xhaka', 'Xherdan Shaqiri', 'Breel Embolo', 'Manuel Akanji', 'Yann Sommer', 'Denis Zakaria', 'Remo Freuler', 'Ruben Vargas'],
    'brazil': ['Vinícius Júnior', 'Rodrygo', 'Neymar Jr', 'Bruno Guimarães', 'Lucas Paquetá', 'Raphinha', 'Gabriel Martinelli', 'Casemiro'],
    'morocco': ['Achraf Hakimi', 'Hakim Ziyech', 'Youssef En-Nesyri', 'Sofyan Amrabat', 'Azzedine Ounahi', 'Amine Harit', 'Brahim Díaz', 'Ismael Saibari'],
    'haiti': ['Frantzdy Pierrot', 'Duckens Nazon', 'Derrick Etienne Jr', 'Carlens Arcus', 'Danley Jean Jacques', 'Wilde-Donald Guerrier', 'Ricardo Adé'],
    'scotland': ['John McGinn', 'Scott McTominay', 'Andrew Robertson', 'Callum McGregor', 'Che Adams', 'Billy Gilmour', 'Ryan Christie', 'Lewis Ferguson'],
    'usa': ['Christian Pulisic', 'Weston McKennie', 'Timothy Weah', 'Folarin Balogun', 'Giovanni Reyna', 'Tyler Adams', 'Yunus Musah', 'Antonee Robinson'],
    'united states': ['Christian Pulisic', 'Weston McKennie', 'Timothy Weah', 'Folarin Balogun', 'Giovanni Reyna', 'Tyler Adams', 'Yunus Musah', 'Antonee Robinson'],
    'paraguay': ['Miguel Almirón', 'Julio Enciso', 'Antonio Sanabria', 'Mathías Villasanti', 'Gustavo Gómez', 'Junior Alonso', 'Damian Bobadilla', 'Mauricio'],
    'australia': ['Mathew Ryan', 'Jackson Irvine', 'Harry Souttar', 'Mitchell Duke', 'Craig Goodwin', 'Connor Metcalfe', 'Nestory Irankunda', 'Jordan Bos'],
    'turkey': ['Hakan Çalhanoğlu', 'Arda Güler', 'Kenan Yıldız', 'Kerem Aktürkoğlu', 'Barış Alper Yılmaz', 'Orkun Kökçü', 'Salih Özcan', 'Ferdi Kadıoğlu'],
    'turkiye': ['Hakan Çalhanoğlu', 'Arda Güler', 'Kenan Yıldız', 'Kerem Aktürkoğlu', 'Barış Alper Yılmaz', 'Orkun Kökçü', 'Salih Özcan', 'Ferdi Kadıoğlu'],
    'germany': ['Florian Wirtz', 'Jamal Musiala', 'Kai Havertz', 'Leroy Sané', 'İlkay Gündoğan', 'Joshua Kimmich', 'Toni Kroos', 'Nico Schlotterbeck'],
    'curacao': ['Juninho Bacuna', 'Leandro Bacuna', 'Kenji Gorré', 'Juriën Gaari', 'Gervane Kastaneer', 'Rangelo Janga', 'Livano Comenencia'],
    'curaçao': ['Juninho Bacuna', 'Leandro Bacuna', 'Kenji Gorré', 'Juriën Gaari', 'Gervane Kastaneer', 'Rangelo Janga', 'Livano Comenencia'],
    'ivory coast': ['Sébastien Haller', 'Franck Kessié', 'Simon Adingra', 'Seko Fofana', 'Ibrahim Sangaré', 'Ousmane Diomande', 'Amad Diallo', 'Serge Aurier'],
    'cote d\'ivoire': ['Sébastien Haller', 'Franck Kessié', 'Simon Adingra', 'Seko Fofana', 'Ibrahim Sangaré', 'Ousmane Diomande', 'Amad Diallo', 'Serge Aurier'],
    'ecuador': ['Enner Valencia', 'Moises Caicedo', 'Piero Hincapié', 'Pervis Estupiñán', 'Kendry Páez', 'Angelo Preciado', 'Willian Pacho', 'Félix Torres'],
    'netherlands': ['Virgil van Dijk', 'Memphis Depay', 'Cody Gakpo', 'Frenkie de Jong', 'Xavi Simons', 'Denzel Dumfries', 'Matthijs de Ligt', 'Crysencio Summerville'],
    'japan': ['Kaoru Mitoma', 'Takefusa Kubo', 'Wataru Endo', 'Ritsu Doan', 'Ayase Ueda', 'Takumi Minamino', 'Daichi Kamada', 'Ko Itakura'],
    'sweden': ['Alexander Isak', 'Viktor Gyökeres', 'Dejan Kulusevski', 'Emil Forsberg', 'Victor Lindelöf', 'Jens Cajuste', 'Yasin Ayari', 'Mattias Svanberg'],
    'tunisia': ['Youssef Msakni', 'Montassar Talbi', 'Aissa Laïdouni', 'Ellyes Skhiri', 'Hamza Rafia', 'Sayfallah Ltaief', 'Wajdi Kechrida', 'Ali Abdi'],
    'belgium': ['Kevin De Bruyne', 'Romelu Lukaku', 'Leandro Trossard', 'Jérémy Doku', 'Amadou Onana', 'Lois Openda', 'Wout Faes', 'Youri Tielemans'],
    'egypt': ['Mohamed Salah', 'Mostafa Mohamed', 'Trezeguet', 'Omar Marmoush', 'Mohamed Elneny', 'Ahmed Hegazi', 'Emam Ashour', 'Zizo'],
    'iran': ['Mehdi Taremi', 'Sardar Azmoun', 'Alireza Jahanbakhsh', 'Saman Ghoddos', 'Mehdi Ghayedi', 'Shojae Khalilzadeh', 'Ramin Rezaeian'],
    'new zealand': ['Chris Wood', 'Liborato Cacace', 'Ben Waine', 'Matthew Garbett', 'Joe Bell', 'Sarpreet Singh', 'Marko Stamenic', 'Tyler Bindon'],
    'spain': ['Rodri', 'Alvaro Morata', 'Lamine Yamal', 'Pedri', 'Gavi', 'Dani Olmo', 'Nico Williams', 'Robin Le Normand'],
    'cape verde': ['Ryan Mendes', 'Garry Rodrigues', 'Jovane Cabral', 'Bebé', 'Logan Costa', 'Kenny Rocha Santos', 'Jamiro Monteiro'],
    'cabo verde': ['Ryan Mendes', 'Garry Rodrigues', 'Jovane Cabral', 'Bebé', 'Logan Costa', 'Kenny Rocha Santos', 'Jamiro Monteiro'],
    'saudi arabia': ['Salem Al-Dawsari', 'Firas Al-Buraikan', 'Saleh Al-Shehri', 'Abdulrahman Ghareeb', 'Mohamed Kanno', 'Saud Abdulhamid', 'Ali Lajami'],
    'saudia arabia': ['Salem Al-Dawsari', 'Firas Al-Buraikan', 'Saleh Al-Shehri', 'Abdulrahman Ghareeb', 'Mohamed Kanno', 'Saud Abdulhamid', 'Ali Lajami'],
    'uruguay': ['Federico Valverde', 'Darwin Núñez', 'Luis Suárez', 'Ronald Araújo', 'Facundo Pellistri', 'Nicolás de la Cruz', 'Manuel Ugarte', 'Mathías Olivera'],
    'france': ['Kylian Mbappé', 'Antoine Griezmann', 'Olivier Giroud', 'Ousmane Dembélé', 'Aurelien Tchouaméni', 'Eduardo Camavinga', 'William Saliba'],
    'senegal': ['Sadio Mané', 'Nicolas Jackson', 'Ismaïla Sarr', 'Lamine Camara', 'Pape Matar Sarr', 'Kalidou Koulibaly', 'Edouard Mendy'],
    'iraq': ['Aymen Hussein', 'Ali Jasim', 'Ibrahim Bayesh', 'Mohanad Ali', 'Youssef Amyn', 'Amir Al-Ammari', 'Rebin Sulaka'],
    'norway': ['Erling Haaland', 'Martin Ødegaard', 'Alexander Sørloth', 'Antonio Nusa', 'Oscar Bobb', 'Sander Berge', 'Julian Ryerson'],
    'argentina': ['Lionel Messi', 'Lautaro Martínez', 'Julián Álvarez', 'Angel Di María', 'Enzo Fernández', 'Alexis Mac Allister', 'Rodrigo De Paul'],
    'algeria': ['Riyad Mahrez', 'Baghdad Bounedjah', 'Amine Gouiri', 'Farès Chaïbi', 'Houssem Aouar', 'Ismaël Bennacer', 'Rayan Aït-Nouri'],
    'austria': ['Marcel Sabitzer', 'Christoph Baumgartner', 'Konrad Laimer', 'Michael Gregoritsch', 'Patrick Wimmer', 'Stefan Lainer', 'Kevin Danso'],
    'jordan': ['Musa Al-Taamari', 'Yazan Al-Naimat', 'Ali Olwan', 'Nizar Al-Rashdan', 'Mahmoud Al-Mardi', 'Ehsan Haddad'],
    'portugal': ['Cristiano Ronaldo', 'Bruno Fernandes', 'Bernardo Silva', 'Rafael Leão', 'João Félix', 'Diogo Jota', 'Vitinha', 'Rúben Dias'],
    'dr congo': ['Yoane Wissa', 'Cédric Bakambu', 'Meschack Elia', 'Samuel Moutoussamy', 'Charles Pickel', 'Chancel Mbemba', 'Arthur Masuaku'],
    'congo dr': ['Yoane Wissa', 'Cédric Bakambu', 'Meschack Elia', 'Samuel Moutoussamy', 'Charles Pickel', 'Chancel Mbemba', 'Arthur Masuaku'],
    'uzbekistan': ['Eldor Shomurodov', 'Oston Urunov', 'Abbosbek Fayzullaev', 'Jaloliddin Masharipov', 'Odiljon Hamrobekov', 'Husniddin Aliqulov'],
    'colombia': ['Luis Díaz', 'James Rodríguez', 'Jhon Arias', 'Rafael Santos Borré', 'Jhon Durán', 'Jefferson Lerma', 'Daniel Muñoz', 'Davinson Sánchez'],
    'england': ['Harry Kane', 'Jude Bellingham', 'Phil Foden', 'Bukayoko Saka', 'Declan Rice', 'Cole Palmer', 'John Stones', 'Kyle Walker'],
    'croatia': ['Luka Modrić', 'Andrej Kramarić', 'Ivan Perišić', 'Mateo Kovačić', 'Mario Pašalić', 'Joško Gvardiol', 'Josip Šutalo'],
    'ghana': ['Mohammed Kudus', 'Inaki Williams', 'Jordan Ayew', 'Antoine Semenyo', 'Salis Abdul Samed', 'Alexander Djiku', 'Alidu Seidu'],
    'panama': ['José Fajardo', 'Ismael Díaz', 'Adalberto Carrasquilla', 'Yoel Bárcenas', 'Aníbal Godoy', 'Fidel Escobar', 'Michael Amir Murillo'],
  };

  static String getDeterministicPlayer(String teamName, int index) {
    final cleanName = teamName.trim().toLowerCase();
    final players = _countryPlayers[cleanName];
    if (players != null && players.isNotEmpty) {
      return players[index % players.length];
    }
    return '${teamName.split(' ')[0]} Player ${index + 1}';
  }

  static bool isTesting = false;

  static List<int> getDeterministicScore(int matchNumber) {
    final home = (matchNumber * 3 + 1) % 4;
    final away = (matchNumber * 7 + 2) % 3;
    return [home, away];
  }

  static List<MatchGoals> getMatchGoals(int matchNumber, String homeTeam, String awayTeam) {
    if (matchNumber == 1) {
      return [
        MatchGoals(9, 'Julián Quiñones', true),
        MatchGoals(67, 'Raúl Jiménez', true),
      ];
    }
    if (matchNumber == 2) {
      return [
        MatchGoals(59, 'Ladislav Krejcí', false),
        MatchGoals(67, 'Hwang In-Beom', true),
        MatchGoals(80, 'Oh Hyeon-Gyu', true),
      ];
    }
    if (matchNumber == 7) {
      return [
        MatchGoals(21, 'Jovo Lukić', false),
        MatchGoals(78, 'Cyle Larin', true),
      ];
    }
    if (matchNumber == 8) {
      return [
        MatchGoals(17, 'Breel Embolo', false, detail: 'Penalty Goal!'),
        MatchGoals(90 + 4, 'Boualem Khoukhi', true),
      ];
    }
    if (matchNumber == 13) {
      return [
        MatchGoals(21, 'Ismael Saibari', false),
        MatchGoals(32, 'Vinícius Júnior', true),
      ];
    }
    if (matchNumber == 14) {
      return [
        MatchGoals(28, 'John McGinn', false),
      ];
    }
    if (matchNumber == 19) {
      return [
        MatchGoals(7, 'Damian Bobadilla', true, detail: 'Own Goal!'),
        MatchGoals(31, 'Folarin Balogun', true),
        MatchGoals(45 + 5, 'Folarin Balogun', true),
        MatchGoals(73, 'Mauricio', false),
        MatchGoals(90 + 8, 'Giovanni Reyna', true),
      ];
    }
    if (matchNumber == 20) {
      return [
        MatchGoals(27, 'Nestory Irankunda', true),
        MatchGoals(75, 'Connor Metcalfe', true),
      ];
    }
    if (matchNumber == 25) {
      return [
        MatchGoals(6, 'Felix Nmecha', true),
        MatchGoals(21, 'Livano Comenencia', false),
        MatchGoals(38, 'Nico Schlotterbeck', true),
        MatchGoals(45 + 5, 'Kai Havertz', true, detail: 'Penalty Goal!'),
        MatchGoals(47, 'Jamal Musiala', true),
        MatchGoals(68, 'Nathaniel Brown', true),
        MatchGoals(78, 'Deniz Undav', true),
        MatchGoals(88, 'Kai Havertz', true),
      ];
    }
    if (matchNumber == 26) {
      return [
        MatchGoals(90, 'Amad Diallo', true),
      ];
    }
    if (matchNumber == 31) {
      return [
        MatchGoals(51, 'Virgil van Dijk', true),
        MatchGoals(57, 'Keito Nakamura', false),
        MatchGoals(64, 'Crysencio Summerville', true),
        MatchGoals(88, 'Daichi Kamada', false),
      ];
    }
    if (matchNumber == 32) {
      return [
        MatchGoals(7, 'Yasin Ayari', true),
        MatchGoals(30, 'Alexander Isak', true),
        MatchGoals(43, 'Omar Rekik', false),
        MatchGoals(59, 'Viktor Gyökeres', true),
        MatchGoals(84, 'Mattias Svanberg', true),
        MatchGoals(90 + 6, 'Yasin Ayari', true),
      ];
    }
    if (matchNumber == 34) {
      return [
        MatchGoals(10, getDeterministicPlayer(awayTeam, 0), false),
        MatchGoals(30, getDeterministicPlayer(awayTeam, 1), false),
        MatchGoals(50, getDeterministicPlayer(awayTeam, 2), false),
      ];
    }
    
    final List<MatchGoals> goals = [];
    final homeCount = (matchNumber * 3 + 1) % 4;
    final awayCount = (matchNumber * 7 + 2) % 3;
    
    for (int g = 0; g < homeCount; g++) {
      goals.add(MatchGoals(10 + g * 20, getDeterministicPlayer(homeTeam, g), true));
    }
    for (int g = 0; g < awayCount; g++) {
      goals.add(MatchGoals(15 + g * 25, getDeterministicPlayer(awayTeam, g), false));
    }
    return goals;
  }

  static void resolveMatchDynamicState(MatchModel m, DateTime now) {
    if (isTesting) return;
    final diff = now.difference(m.dateTime.toUtc());
    if (diff.isNegative) {
      m.status = 'upcoming';
      m.homeScore = 0;
      m.awayScore = 0;
      m.timeline = [];
      return;
    }
    
    final rawElapsed = diff.inMinutes;
    final elapsed = rawElapsed <= 45
        ? rawElapsed
        : (rawElapsed <= 60 ? 45 : rawElapsed - 15);
    final goals = getMatchGoals(m.matchNumber, m.homeTeam, m.awayTeam);
    
    if (rawElapsed <= 120) {
      m.status = 'live';
      m.homeScore = goals.where((g) => g.isHome && g.minute <= elapsed).length;
      m.awayScore = goals.where((g) => !g.isHome && g.minute <= elapsed).length;
      
      final List<TimelineEvent> timeline = [
        TimelineEvent(
          minute: 0,
          type: 'kickoff',
          player: 'Referee',
          team: 'System',
          detail: 'Match Started at ${m.venue}',
        )
      ];
      if (rawElapsed > 45) {
        timeline.insert(
          0,
          TimelineEvent(
            minute: 45,
            type: 'info',
            player: 'Referee',
            team: 'System',
            detail: 'Half-Time',
          ),
        );
      }
      for (var g in goals) {
        if (g.minute <= elapsed) {
          timeline.insert(
            0,
            TimelineEvent(
              minute: g.minute,
              type: 'goal',
              player: g.player,
              team: g.isHome ? m.homeTeam : m.awayTeam,
              detail: g.detail,
            ),
          );
        }
      }
      m.timeline = timeline;
    } else {
      m.status = 'completed';
      m.homeScore = goals.where((g) => g.isHome).length;
      m.awayScore = goals.where((g) => !g.isHome).length;
      
      final List<TimelineEvent> timeline = [
        TimelineEvent(
          minute: 0,
          type: 'kickoff',
          player: 'Referee',
          team: 'System',
          detail: 'Match Started',
        )
      ];
      for (var g in goals) {
        timeline.insert(
          0,
          TimelineEvent(
            minute: g.minute,
            type: 'goal',
            player: g.player,
            team: g.isHome ? m.homeTeam : m.awayTeam,
            detail: g.detail,
          ),
        );
      }
      timeline.insert(
        0,
        TimelineEvent(
          minute: 90,
          type: 'fulltime',
          player: 'Referee',
          team: 'System',
          detail: 'Full-Time: Final score ${m.homeScore} - ${m.awayScore}',
        ),
      );
      m.timeline = timeline;
    }
  }

  static bool updateMatchesStatusAndScores(List<MatchModel> matches) {
    if (isTesting) return false;
    final now = DateTime.now().toUtc();
    for (var m in matches) {
      resolveMatchDynamicState(m, now);
    }
    return true;
  }

  // Parses date "2026-06-11" and time "13:00 UTC-6" into a correct UTC DateTime
  static DateTime parseDateTime(String dateStr, String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      final hm = parts[0].split(':');
      final hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);

      final ymd = dateStr.trim().split('-');
      final year = int.parse(ymd[0]);
      final month = int.parse(ymd[1]);
      final day = int.parse(ymd[2]);

      var dt = DateTime.utc(year, month, day, hour, minute);

      if (parts.length > 1) {
        final tzStr = parts[1];
        if (tzStr.contains('UTC-')) {
          final offsetStr = tzStr.replaceAll('UTC-', '');
          final offset = int.tryParse(offsetStr) ?? 0;
          dt = dt.add(Duration(hours: offset));
        } else if (tzStr.contains('UTC+')) {
          final offsetStr = tzStr.replaceAll('UTC+', '');
          final offset = int.tryParse(offsetStr) ?? 0;
          dt = dt.subtract(Duration(hours: offset));
        }
      }
      return dt;
    } catch (e) {
      print("Error parsing DateTime: $e");
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  Future<List<MatchModel>> loadMatches() async {
    List<MatchModel>? networkMatches;

    // 1. Try fetching from the official openfootball network endpoint
    if (!isTesting) {
      try {
        final response = await http
            .get(Uri.parse('https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          networkMatches = parseMatchesJson(response.body);
        }
      } catch (e) {
        print("Failed to sync matches from network API: $e. Falling back to local offline schedule.");
      }
    }

    // 2. Load/Merge with cached matches from local storage
    try {
      final cachedJson = StorageService.getSimulatedMatchesJson();
      if (cachedJson != null) {
        final List<dynamic> decoded = json.decode(cachedJson);
        final cachedMatches = decoded.map((item) => MatchModel.fromJson(item as Map<String, dynamic>)).toList();
        
        // Self-healing migration: if cached matches count is outdated, overwrite with complete initial schedule
        final initialCount = InitialSchedule.getMatches().length;
        if (cachedMatches.length < initialCount) {
          final initial = InitialSchedule.getMatches();
          if (networkMatches != null && networkMatches.isNotEmpty) {
            for (var m in initial) {
              final nm = networkMatches.firstWhere((n) => n.matchNumber == m.matchNumber, orElse: () => m);
              m.status = nm.status;
              m.homeScore = nm.homeScore;
              m.awayScore = nm.awayScore;
              m.timeline = nm.timeline;
            }
          } else {
            updateMatchesStatusAndScores(initial);
          }
          await saveMatches(initial);
          return initial;
        }

        // Merge network scores if available
        if (networkMatches != null && networkMatches.isNotEmpty) {
          for (var cm in cachedMatches) {
            final nm = networkMatches.firstWhere((n) => n.matchNumber == cm.matchNumber, orElse: () => cm);
            cm.status = nm.status;
            cm.homeScore = nm.homeScore;
            cm.awayScore = nm.awayScore;
            cm.timeline = nm.timeline;
          }
          await saveMatches(cachedMatches);
        } else {
          final changed = updateMatchesStatusAndScores(cachedMatches);
          if (changed) {
            await saveMatches(cachedMatches);
          }
        }
        return cachedMatches;
      }
    } catch (e) {
      print("Error loading cached matches: $e");
    }

    // 3. Fallback/New Start
    if (networkMatches != null && networkMatches.isNotEmpty) {
      await saveMatches(networkMatches);
      return networkMatches;
    }

    final initial = InitialSchedule.getMatches();
    updateMatchesStatusAndScores(initial);
    await saveMatches(initial);
    return initial;
  }

  static List<MatchModel> parseMatchesJson(String jsonStr) {
    try {
      final Map<String, dynamic> data = json.decode(jsonStr);
      final List<dynamic> matchesList = data['matches'] ?? [];
      final List<MatchModel> parsedMatches = [];
      
      for (var i = 0; i < matchesList.length; i++) {
        final m = matchesList[i];
        
        // Robust Team Parsing (strings or nested maps)
        final team1Val = m['team1'];
        final team2Val = m['team2'];
        String homeTeam = 'Home Team';
        String awayTeam = 'Away Team';
        if (team1Val is String) {
          homeTeam = team1Val;
        } else if (team1Val is Map) {
          homeTeam = team1Val['name'] as String? ?? 'Home Team';
        }
        if (team2Val is String) {
          awayTeam = team2Val;
        } else if (team2Val is Map) {
          awayTeam = team2Val['name'] as String? ?? 'Away Team';
        }

        final dateStr = m['date'] as String? ?? '2026-06-11';
        final timeStr = m['time'] as String? ?? '12:00 UTC';
        final matchTime = parseDateTime(dateStr, timeStr);
        
        // Defensive Score Parsing (strings, integers, nulls, and nested score.ft list)
        int? homeScore;
        int? awayScore;
        if (m['score1'] != null) {
          homeScore = int.tryParse(m['score1'].toString());
        }
        if (m['score2'] != null) {
          awayScore = int.tryParse(m['score2'].toString());
        }
        if (homeScore == null && awayScore == null && m['score'] != null) {
          final scoreMap = m['score'];
          if (scoreMap is Map) {
            final ft = scoreMap['ft'];
            if (ft is List && ft.length >= 2) {
              homeScore = int.tryParse(ft[0].toString());
              awayScore = int.tryParse(ft[1].toString());
            }
          }
        }
        final hasResult = homeScore != null && awayScore != null;

        final now = DateTime.now().toUtc();
        String status = 'upcoming';
        if (hasResult) {
          status = 'completed';
        } else if (!isTesting) {
          final diff = now.difference(matchTime);
          if (!diff.isNegative) {
            if (diff.inMinutes <= 120) {
              status = 'live';
            } else {
              status = 'completed';
            }
          }
        }

        List<TimelineEvent> timeline = [];
        if (hasResult) {
          timeline.add(
            TimelineEvent(
              minute: 0,
              type: 'kickoff',
              player: 'Referee',
              team: 'System',
              detail: 'Match Started',
            ),
          );

          // Parse actual player names and goal details if available from feed
          final List<dynamic> g1 = m['goals1'] is List ? m['goals1'] as List : [];
          final List<dynamic> g2 = m['goals2'] is List ? m['goals2'] as List : [];
          final List<TimelineEvent> goalEvents = [];

          for (var goal in g1) {
            if (goal is Map) {
              final name = goal['name'] as String? ?? 'Home Player';
              final minStr = goal['minute']?.toString() ?? '10';
              final minute = int.tryParse(minStr.split('+')[0]) ?? 10;
              final isPenalty = goal['penalty'] == true;
              final isOwnGoal = goal['owngoal'] == true;
              goalEvents.add(
                TimelineEvent(
                  minute: minute,
                  type: 'goal',
                  player: name,
                  team: homeTeam,
                  detail: isOwnGoal ? 'Own Goal!' : (isPenalty ? 'Penalty Goal!' : 'Goal!'),
                ),
              );
            }
          }

          for (var goal in g2) {
            if (goal is Map) {
              final name = goal['name'] as String? ?? 'Away Player';
              final minStr = goal['minute']?.toString() ?? '15';
              final minute = int.tryParse(minStr.split('+')[0]) ?? 15;
              final isPenalty = goal['penalty'] == true;
              final isOwnGoal = goal['owngoal'] == true;
              goalEvents.add(
                TimelineEvent(
                  minute: minute,
                  type: 'goal',
                  player: name,
                  team: awayTeam,
                  detail: isOwnGoal ? 'Own Goal!' : (isPenalty ? 'Penalty Goal!' : 'Goal!'),
                ),
              );
            }
          }

          // Sort goal events chronologically before reverse-inserting
          goalEvents.sort((a, b) => a.minute.compareTo(b.minute));
          for (var ge in goalEvents) {
            timeline.insert(0, ge);
          }

          // Fallback to generated goals if list is empty but scores are non-zero
          if (goalEvents.isEmpty && (homeScore > 0 || awayScore > 0)) {
            final hScore = homeScore;
            for (int g = 0; g < hScore; g++) {
              timeline.insert(
                0,
                TimelineEvent(
                  minute: 10 + g * 20,
                  type: 'goal',
                  player: getDeterministicPlayer(homeTeam, g),
                  team: homeTeam,
                  detail: 'Goal!',
                ),
              );
            }
            final aScore = awayScore;
            for (int g = 0; g < aScore; g++) {
              timeline.insert(
                0,
                TimelineEvent(
                  minute: 15 + g * 25,
                  type: 'goal',
                  player: getDeterministicPlayer(awayTeam, g),
                  team: awayTeam,
                  detail: 'Goal!',
                ),
              );
            }
          }

          timeline.insert(
            0,
            TimelineEvent(
              minute: 90,
              type: 'fulltime',
              player: 'Referee',
              team: 'System',
              detail: 'Full-Time: Final score $homeScore - $awayScore',
            ),
          );
        } else if (!isTesting) {
          final mockModel = MatchModel(
            id: 'temp',
            matchNumber: i + 1,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeFlag: '',
            awayFlag: '',
            dateTime: matchTime,
            venue: m['ground'] as String? ?? 'Stadium Venue',
            city: m['ground'] as String? ?? 'Host City',
            country: 'Host Nation',
            stage: m['round'] as String? ?? 'Group Stage',
            groupName: m['group'] as String? ?? 'N/A',
          );
          resolveMatchDynamicState(mockModel, now);
          status = mockModel.status;
          homeScore = mockModel.homeScore;
          awayScore = mockModel.awayScore;
          timeline = mockModel.timeline;
        } else {
          homeScore = 0;
          awayScore = 0;
          timeline = [];
        }

        parsedMatches.add(
          MatchModel(
            id: 'match_${i + 1}',
            matchNumber: i + 1,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeFlag: getFlag(homeTeam),
            awayFlag: getFlag(awayTeam),
            dateTime: matchTime,
            venue: m['ground'] as String? ?? 'Stadium Venue',
            city: m['ground'] as String? ?? 'Host City',
            country: 'Host Nation',
            stage: m['round'] as String? ?? 'Group Stage',
            groupName: m['group'] as String? ?? 'N/A',
            status: status,
            homeScore: homeScore ?? 0,
            awayScore: awayScore ?? 0,
            timeline: timeline,
          ),
        );
      }
      return parsedMatches;
    } catch (e) {
      print("Error parsing matches JSON: $e");
      return [];
    }
  }

  Future<void> saveMatches(List<MatchModel> matches) async {
    try {
      final jsonStr = json.encode(matches.map((m) => m.toJson()).toList());
      await StorageService.saveSimulatedMatchesJson(jsonStr);
    } catch (e) {
      print("Error saving matches: $e");
    }
  }

  Future<void> resetSchedule() async {
    await StorageService.clearSimulatedMatches();
  }
}
