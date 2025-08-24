import 'package:geolocator/geolocator.dart';

class CountryInfo {
  final String code;
  final String name;
  final String flag;
  final String format;
  final double lat;
  final double lng;

  const CountryInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.format,
    required this.lat,
    required this.lng,
  });
}

class CountryService {
  static const List<CountryInfo> countries = [
    // Europe
    CountryInfo(code: 'AL', name: 'Albania', flag: '🇦🇱', format: 'LL CC LLL', lat: 41.1533, lng: 19.8172),
    CountryInfo(code: 'AD', name: 'Andorra', flag: '🇦🇩', format: 'L NNNN', lat: 42.5462, lng: 1.6016),
    CountryInfo(code: 'AT', name: 'Austria', flag: '🇦🇹', format: 'L-NN LLL', lat: 47.5162, lng: 14.5501),
    CountryInfo(code: 'BY', name: 'Belarus', flag: '🇧🇾', format: 'CCCC LL-C', lat: 53.7098, lng: 27.9534),
    CountryInfo(code: 'BE', name: 'Belgium', flag: '🇧🇪', format: 'C LLL CCC', lat: 50.5039, lng: 4.4699),
    CountryInfo(code: 'BA', name: 'Bosnia and Herzegovina', flag: '🇧🇦', format: 'LLL-CC-LL', lat: 43.9159, lng: 17.6791),
    CountryInfo(code: 'BG', name: 'Bulgaria', flag: '🇧🇬', format: 'CC LLLL CC', lat: 42.7339, lng: 25.4858),
    CountryInfo(code: 'HR', name: 'Croatia', flag: '🇭🇷', format: 'LL CCC LL', lat: 45.1000, lng: 15.2000),
    CountryInfo(code: 'CY', name: 'Cyprus', flag: '🇨🇾', format: 'LLL CCC', lat: 35.1264, lng: 33.4299),
    CountryInfo(code: 'CZ', name: 'Czech Republic', flag: '🇨🇿', format: 'C LLL CC', lat: 49.8175, lng: 15.4730),
    CountryInfo(code: 'DK', name: 'Denmark', flag: '🇩🇰', format: 'LL CC CCC', lat: 56.2639, lng: 9.5018),
    CountryInfo(code: 'EE', name: 'Estonia', flag: '🇪🇪', format: 'CCC LLL', lat: 58.5953, lng: 25.0136),
    CountryInfo(code: 'FI', name: 'Finland', flag: '🇫🇮', format: 'LLL-CCC', lat: 61.9241, lng: 25.7482),
    CountryInfo(code: 'FR', name: 'France', flag: '🇫🇷', format: 'LL-CCC-LL', lat: 46.6034, lng: 1.8883),
    CountryInfo(code: 'DE', name: 'Germany', flag: '🇩🇪', format: 'LLL CC CCCC', lat: 51.1657, lng: 10.4515),
    CountryInfo(code: 'GR', name: 'Greece', flag: '🇬🇷', format: 'LLL-CCCC', lat: 39.0742, lng: 21.8243),
    CountryInfo(code: 'HU', name: 'Hungary', flag: '🇭🇺', format: 'LLL-CCC', lat: 47.1625, lng: 19.5033),
    CountryInfo(code: 'IS', name: 'Iceland', flag: '🇮🇸', format: 'LL CCC', lat: 64.9631, lng: -19.0208),
    CountryInfo(code: 'IE', name: 'Ireland', flag: '🇮🇪', format: 'CC-CCC-LLL', lat: 53.4129, lng: -8.2439),
    CountryInfo(code: 'IT', name: 'Italy', flag: '🇮🇹', format: 'LL CCC LL', lat: 41.8719, lng: 12.5674),
    CountryInfo(code: 'XK', name: 'Kosovo', flag: '🇽🇰', format: 'CC LLL CC', lat: 42.6026, lng: 20.9020),
    CountryInfo(code: 'LV', name: 'Latvia', flag: '🇱🇻', format: 'LL-CCCC', lat: 56.8796, lng: 24.6032),
    CountryInfo(code: 'LI', name: 'Liechtenstein', flag: '🇱🇮', format: 'FL CCCCC', lat: 47.1660, lng: 9.5554),
    CountryInfo(code: 'LT', name: 'Lithuania', flag: '🇱🇹', format: 'LLL CCC', lat: 55.1694, lng: 23.8813),
    CountryInfo(code: 'LU', name: 'Luxembourg', flag: '🇱🇺', format: 'LLLL', lat: 49.8153, lng: 6.1296),
    CountryInfo(code: 'MT', name: 'Malta', flag: '🇲🇹', format: 'LLL CCC', lat: 35.9375, lng: 14.3754),
    CountryInfo(code: 'MD', name: 'Moldova', flag: '🇲🇩', format: 'LLL CCC', lat: 47.4116, lng: 28.3699),
    CountryInfo(code: 'MC', name: 'Monaco', flag: '🇲🇨', format: 'CCCC', lat: 43.7384, lng: 7.4246),
    CountryInfo(code: 'ME', name: 'Montenegro', flag: '🇲🇪', format: 'LL CCC LL', lat: 42.7087, lng: 19.3744),
    CountryInfo(code: 'NL', name: 'Netherlands', flag: '🇳🇱', format: 'LL-CC-CC', lat: 52.1326, lng: 5.2913),
    CountryInfo(code: 'MK', name: 'North Macedonia', flag: '🇲🇰', format: 'LL CCCC L', lat: 41.6086, lng: 21.7453),
    CountryInfo(code: 'NO', name: 'Norway', flag: '🇳🇴', format: 'LL CCCCC', lat: 60.4720, lng: 8.4689),
    CountryInfo(code: 'PL', name: 'Poland', flag: '🇵🇱', format: 'LL CCCCC', lat: 51.9194, lng: 19.1451),
    CountryInfo(code: 'PT', name: 'Portugal', flag: '🇵🇹', format: 'LL-CC-LL', lat: 39.3999, lng: -8.2245),
    CountryInfo(code: 'RO', name: 'Romania', flag: '🇷🇴', format: 'CC CC LLL', lat: 45.9432, lng: 24.9668),
    CountryInfo(code: 'RU', name: 'Russia', flag: '🇷🇺', format: 'L CCC LL CC', lat: 61.5240, lng: 105.3188),
    CountryInfo(code: 'SM', name: 'San Marino', flag: '🇸🇲', format: 'CCCCC', lat: 43.9424, lng: 12.4578),
    CountryInfo(code: 'RS', name: 'Serbia', flag: '🇷🇸', format: 'LL CCC LL', lat: 44.0165, lng: 21.0059),
    CountryInfo(code: 'SK', name: 'Slovakia', flag: '🇸🇰', format: 'LL CCC LL', lat: 48.6690, lng: 19.6990),
    CountryInfo(code: 'SI', name: 'Slovenia', flag: '🇸🇮', format: 'LL CCC LL', lat: 46.1512, lng: 14.9955),
    CountryInfo(code: 'ES', name: 'Spain', flag: '🇪🇸', format: 'CCCC LLL', lat: 40.4637, lng: -3.7492),
    CountryInfo(code: 'SE', name: 'Sweden', flag: '🇸🇪', format: 'LLL CCC', lat: 60.1282, lng: 18.6435),
    CountryInfo(code: 'CH', name: 'Switzerland', flag: '🇨🇭', format: 'LL CCCCCC', lat: 46.8182, lng: 8.2275),
    CountryInfo(code: 'TR', name: 'Turkey', flag: '🇹🇷', format: 'CC LLL CCC', lat: 38.9637, lng: 35.2433),
    CountryInfo(code: 'UA', name: 'Ukraine', flag: '🇺🇦', format: 'LL CCCC LL', lat: 48.3794, lng: 31.1656),
    CountryInfo(code: 'GB', name: 'United Kingdom', flag: '🇬🇧', format: 'LLCC LLL', lat: 55.3781, lng: -3.4360),
    CountryInfo(code: 'VA', name: 'Vatican City', flag: '🇻🇦', format: 'LLL CCC', lat: 41.9029, lng: 12.4534),

    // North America
    CountryInfo(code: 'AG', name: 'Antigua and Barbuda', flag: '🇦🇬', format: 'L CCCC', lat: 17.0608, lng: -61.7964),
    CountryInfo(code: 'BS', name: 'Bahamas', flag: '🇧🇸', format: 'CCCCC', lat: 25.0343, lng: -77.3963),
    CountryInfo(code: 'BB', name: 'Barbados', flag: '🇧🇧', format: 'L CCCC', lat: 13.1939, lng: -59.5432),
    CountryInfo(code: 'BZ', name: 'Belize', flag: '🇧🇿', format: 'L CCC', lat: 17.1899, lng: -88.4976),
    CountryInfo(code: 'CA', name: 'Canada', flag: '🇨🇦', format: 'LLLL CCC', lat: 56.1304, lng: -106.3468),
    CountryInfo(code: 'CR', name: 'Costa Rica', flag: '🇨🇷', format: 'CCC-LLL', lat: 9.7489, lng: -83.7534),
    CountryInfo(code: 'CU', name: 'Cuba', flag: '🇨🇺', format: 'L CCC CCC', lat: 21.5218, lng: -77.7812),
    CountryInfo(code: 'DM', name: 'Dominica', flag: '🇩🇲', format: 'L CCC', lat: 15.4140, lng: -61.3710),
    CountryInfo(code: 'DO', name: 'Dominican Republic', flag: '🇩🇴', format: 'L CCCCC', lat: 18.7357, lng: -70.1627),
    CountryInfo(code: 'SV', name: 'El Salvador', flag: '🇸🇻', format: 'L CCCCCC', lat: 13.7942, lng: -88.8965),
    CountryInfo(code: 'GD', name: 'Grenada', flag: '🇬🇩', format: 'L CCC', lat: 12.1165, lng: -61.6790),
    CountryInfo(code: 'GT', name: 'Guatemala', flag: '🇬🇹', format: 'L CCCCCC', lat: 15.7835, lng: -90.2308),
    CountryInfo(code: 'HT', name: 'Haiti', flag: '🇭🇹', format: 'CC CCCCC', lat: 18.9712, lng: -72.2852),
    CountryInfo(code: 'HN', name: 'Honduras', flag: '🇭🇳', format: 'LLL CCC', lat: 15.2000, lng: -86.2419),
    CountryInfo(code: 'JM', name: 'Jamaica', flag: '🇯🇲', format: 'LLL CCC', lat: 18.1096, lng: -77.2975),
    CountryInfo(code: 'MX', name: 'Mexico', flag: '🇲🇽', format: 'LLL-CCCC', lat: 23.6345, lng: -102.5528),
    CountryInfo(code: 'NI', name: 'Nicaragua', flag: '🇳🇮', format: 'CCC-LLL', lat: 12.2658, lng: -85.2072),
    CountryInfo(code: 'PA', name: 'Panama', flag: '🇵🇦', format: 'LL CCCC', lat: 8.5380, lng: -80.7821),
    CountryInfo(code: 'KN', name: 'Saint Kitts and Nevis', flag: '🇰🇳', format: 'L CCC', lat: 17.3578, lng: -62.7830),
    CountryInfo(code: 'LC', name: 'Saint Lucia', flag: '🇱🇨', format: 'L CCCC', lat: 13.9094, lng: -60.9789),
    CountryInfo(code: 'VC', name: 'Saint Vincent and the Grenadines', flag: '🇻🇨', format: 'L CCCC', lat: 12.9843, lng: -61.2872),
    CountryInfo(code: 'US', name: 'United States', flag: '🇺🇸', format: 'CLLL CCC', lat: 37.0902, lng: -95.7129),
    CountryInfo(code: 'TT', name: 'Trinidad and Tobago', flag: '🇹🇹', format: 'L CCCCCC', lat: 10.6918, lng: -61.2225),

    // South America
    CountryInfo(code: 'AR', name: 'Argentina', flag: '🇦🇷', format: 'LL CCC LL', lat: -38.4161, lng: -63.6167),
    CountryInfo(code: 'BO', name: 'Bolivia', flag: '🇧🇴', format: 'LLL CCCC', lat: -16.2902, lng: -63.5887),
    CountryInfo(code: 'BR', name: 'Brazil', flag: '🇧🇷', format: 'LLL CCCC', lat: -14.2350, lng: -51.9253),
    CountryInfo(code: 'CL', name: 'Chile', flag: '🇨🇱', format: 'LLCC CC', lat: -35.6751, lng: -71.5430),
    CountryInfo(code: 'CO', name: 'Colombia', flag: '🇨🇴', format: 'LLL CCC', lat: 4.5709, lng: -74.2973),
    CountryInfo(code: 'EC', name: 'Ecuador', flag: '🇪🇨', format: 'LLL-CCCC', lat: -1.8312, lng: -78.1834),
    CountryInfo(code: 'GY', name: 'Guyana', flag: '🇬🇾', format: 'LLL CCCC', lat: 4.8604, lng: -58.9302),
    CountryInfo(code: 'PY', name: 'Paraguay', flag: '🇵🇾', format: 'LLL CCCC', lat: -23.4425, lng: -58.4438),
    CountryInfo(code: 'PE', name: 'Peru', flag: '🇵🇪', format: 'LLL-CCC', lat: -9.1900, lng: -75.0152),
    CountryInfo(code: 'SR', name: 'Suriname', flag: '🇸🇷', format: 'LL CCCC', lat: 3.9193, lng: -56.0278),
    CountryInfo(code: 'UY', name: 'Uruguay', flag: '🇺🇾', format: 'LLL CCCC', lat: -32.5228, lng: -55.7658),
    CountryInfo(code: 'VE', name: 'Venezuela', flag: '🇻🇪', format: 'LLL CCC', lat: 6.4238, lng: -66.5897),

    // Asia
    CountryInfo(code: 'AF', name: 'Afghanistan', flag: '🇦🇫', format: 'CCC LLL CC', lat: 33.9391, lng: 67.7100),
    CountryInfo(code: 'AM', name: 'Armenia', flag: '🇦🇲', format: 'CC LL CCC', lat: 40.0691, lng: 45.0382),
    CountryInfo(code: 'AZ', name: 'Azerbaijan', flag: '🇦🇿', format: 'CC LLL CCC', lat: 40.1431, lng: 47.5769),
    CountryInfo(code: 'BH', name: 'Bahrain', flag: '🇧🇭', format: 'CCCCC', lat: 25.9304, lng: 50.6378),
    CountryInfo(code: 'BD', name: 'Bangladesh', flag: '🇧🇩', format: 'LLL CCCC', lat: 23.6850, lng: 90.3563),
    CountryInfo(code: 'BT', name: 'Bhutan', flag: '🇧🇹', format: 'LL CCC', lat: 27.5142, lng: 90.4336),
    CountryInfo(code: 'BN', name: 'Brunei', flag: '🇧🇳', format: 'L CCCC', lat: 4.5353, lng: 114.7277),
    CountryInfo(code: 'KH', name: 'Cambodia', flag: '🇰🇭', format: 'CC CCCCC', lat: 12.5657, lng: 104.9910),
    CountryInfo(code: 'CN', name: 'China', flag: '🇨🇳', format: 'L L CCCCC', lat: 35.8617, lng: 104.1954),
    CountryInfo(code: 'KP', name: 'North Korea', flag: '🇰🇵', format: 'LLL-CCC', lat: 40.3399, lng: 127.5101),
    CountryInfo(code: 'KR', name: 'South Korea', flag: '🇰🇷', format: 'CCC LL CCCC', lat: 35.9078, lng: 127.7669),
    CountryInfo(code: 'AE', name: 'United Arab Emirates', flag: '🇦🇪', format: 'CCCCC', lat: 23.4241, lng: 53.8478),
    CountryInfo(code: 'PH', name: 'Philippines', flag: '🇵🇭', format: 'LLL CCC', lat: 12.8797, lng: 121.7740),
    CountryInfo(code: 'GE', name: 'Georgia', flag: '🇬🇪', format: 'LLL CCC', lat: 42.3154, lng: 43.3569),
    CountryInfo(code: 'IN', name: 'India', flag: '🇮🇳', format: 'LL CC LLLL', lat: 20.5937, lng: 78.9629),
    CountryInfo(code: 'ID', name: 'Indonesia', flag: '🇮🇩', format: 'L CCCC LL', lat: -0.7893, lng: 113.9213),
    CountryInfo(code: 'IQ', name: 'Iraq', flag: '🇮🇶', format: 'CCCCC L', lat: 33.2232, lng: 43.6793),
    CountryInfo(code: 'IR', name: 'Iran', flag: '🇮🇷', format: 'CC LLL CC', lat: 32.4279, lng: 53.6880),
    CountryInfo(code: 'IL', name: 'Israel', flag: '🇮🇱', format: 'CCC-CC-CC', lat: 31.0461, lng: 34.8516),
    CountryInfo(code: 'JP', name: 'Japan', flag: '🇯🇵', format: 'CCC-LL-CC', lat: 36.2048, lng: 138.2529),
    CountryInfo(code: 'JO', name: 'Jordan', flag: '🇯🇴', format: 'CC CCCCC', lat: 30.5852, lng: 36.2384),
    CountryInfo(code: 'KZ', name: 'Kazakhstan', flag: '🇰🇿', format: 'CCC LLL C', lat: 48.0196, lng: 66.9237),
    CountryInfo(code: 'KG', name: 'Kyrgyzstan', flag: '🇰🇬', format: 'LL CCCC', lat: 41.2044, lng: 74.7661),
    CountryInfo(code: 'KW', name: 'Kuwait', flag: '🇰🇼', format: 'CCCCC', lat: 29.3117, lng: 47.4818),
    CountryInfo(code: 'LA', name: 'Laos', flag: '🇱🇦', format: 'LLL CCCC', lat: 19.8563, lng: 102.4955),
    CountryInfo(code: 'LB', name: 'Lebanon', flag: '🇱🇧', format: 'CCCCC L', lat: 33.8547, lng: 35.8623),
    CountryInfo(code: 'MY', name: 'Malaysia', flag: '🇲🇾', format: 'LLL CCCC', lat: 4.2105, lng: 101.9758),
    CountryInfo(code: 'MV', name: 'Maldives', flag: '🇲🇻', format: 'L CCC', lat: 3.2028, lng: 73.2207),
    CountryInfo(code: 'MN', name: 'Mongolia', flag: '🇲🇳', format: 'CCCC LLL', lat: 46.8625, lng: 103.8467),
    CountryInfo(code: 'MM', name: 'Myanmar', flag: '🇲🇲', format: 'LLL CCCC', lat: 21.9162, lng: 95.9560),
    CountryInfo(code: 'NP', name: 'Nepal', flag: '🇳🇵', format: 'L CCCC', lat: 28.3949, lng: 84.1240),
    CountryInfo(code: 'OM', name: 'Oman', flag: '🇴🇲', format: 'CCCCC L', lat: 21.4735, lng: 55.9754),
    CountryInfo(code: 'PK', name: 'Pakistan', flag: '🇵🇰', format: 'LLL CCCC', lat: 30.3753, lng: 69.3451),
    CountryInfo(code: 'QA', name: 'Qatar', flag: '🇶🇦', format: 'CCCCC', lat: 25.3548, lng: 51.1839),
    CountryInfo(code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦', format: 'CCCC LLL', lat: 23.8859, lng: 45.0792),
    CountryInfo(code: 'SG', name: 'Singapore', flag: '🇸🇬', format: 'LLL CCCC', lat: 1.3521, lng: 103.8198),
    CountryInfo(code: 'LK', name: 'Sri Lanka', flag: '🇱🇰', format: 'LL-CCCC', lat: 7.8731, lng: 80.7718),
    CountryInfo(code: 'SY', name: 'Syria', flag: '🇸🇾', format: 'CCCCC L', lat: 34.8021, lng: 38.9968),
    CountryInfo(code: 'TJ', name: 'Tajikistan', flag: '🇹🇯', format: 'CCCC LL', lat: 38.8610, lng: 71.2761),
    CountryInfo(code: 'TH', name: 'Thailand', flag: '🇹🇭', format: 'L CCCCCC', lat: 15.8700, lng: 100.9925),
    CountryInfo(code: 'TL', name: 'Timor-Leste', flag: '🇹🇱', format: 'L CCCC', lat: -8.8742, lng: 125.7275),
    CountryInfo(code: 'TM', name: 'Turkmenistan', flag: '🇹🇲', format: 'CCCC LL', lat: 38.9697, lng: 59.5563),
    CountryInfo(code: 'UZ', name: 'Uzbekistan', flag: '🇺🇿', format: 'CC LLL CC', lat: 41.3775, lng: 64.5853),
    CountryInfo(code: 'VN', name: 'Vietnam', flag: '🇻🇳', format: 'CC-LLL-CC', lat: 14.0583, lng: 108.2772),
    CountryInfo(code: 'YE', name: 'Yemen', flag: '🇾🇪', format: 'L CCCC', lat: 15.5527, lng: 48.5164),

    // Africa
    CountryInfo(code: 'DZ', name: 'Algeria', flag: '🇩🇿', format: 'CCC CCC CCC', lat: 28.0339, lng: 1.6596),
    CountryInfo(code: 'AO', name: 'Angola', flag: '🇦🇴', format: 'LLL-CCC-LL', lat: -11.2027, lng: 17.8739),
    CountryInfo(code: 'BJ', name: 'Benin', flag: '🇧🇯', format: 'LL-CCCC-L', lat: 9.3077, lng: 2.3158),
    CountryInfo(code: 'BW', name: 'Botswana', flag: '🇧🇼', format: 'L CCCC', lat: -22.3285, lng: 24.6849),
    CountryInfo(code: 'BF', name: 'Burkina Faso', flag: '🇧🇫', format: 'CCCC LL', lat: 12.2383, lng: -1.5616),
    CountryInfo(code: 'BI', name: 'Burundi', flag: '🇧🇮', format: 'L CCCCCC', lat: -3.3731, lng: 29.9189),
    CountryInfo(code: 'CM', name: 'Cameroon', flag: '🇨🇲', format: 'LL CCCC', lat: 7.3697, lng: 12.3547),
    CountryInfo(code: 'CV', name: 'Cape Verde', flag: '🇨🇻', format: 'LL-CCCC', lat: 16.5388, lng: -24.0132),
    CountryInfo(code: 'CF', name: 'Central African Republic', flag: '🇨🇫', format: 'LL CCCC', lat: 6.6111, lng: 20.9394),
    CountryInfo(code: 'TD', name: 'Chad', flag: '🇹🇩', format: 'CCCC LL', lat: 15.4542, lng: 18.7322),
    CountryInfo(code: 'KM', name: 'Comoros', flag: '🇰🇲', format: 'L CCC', lat: -11.6455, lng: 43.3333),
    CountryInfo(code: 'CG', name: 'Congo', flag: '🇨🇬', format: 'L CCCC L', lat: -0.2280, lng: 15.8277),
    CountryInfo(code: 'CD', name: 'Congo (Democratic Republic)', flag: '🇨🇩', format: 'CCCC LL', lat: -4.0383, lng: 21.7587),
    CountryInfo(code: 'CI', name: 'Côte d\'Ivoire', flag: '🇨🇮', format: 'CCCC LL', lat: 7.5399, lng: -5.5471),
    CountryInfo(code: 'DJ', name: 'Djibouti', flag: '🇩🇯', format: 'CCCC', lat: 11.8251, lng: 42.5903),
    CountryInfo(code: 'EG', name: 'Egypt', flag: '🇪🇬', format: 'LLL CCC', lat: 26.0975, lng: 30.0444),
    CountryInfo(code: 'GQ', name: 'Equatorial Guinea', flag: '🇬🇶', format: 'LL CCCC', lat: 1.6508, lng: 10.2679),
    CountryInfo(code: 'ER', name: 'Eritrea', flag: '🇪🇷', format: 'LL CCCC', lat: 15.1794, lng: 39.7823),
    CountryInfo(code: 'SZ', name: 'Eswatini', flag: '🇸🇿', format: 'LLL CCC', lat: -26.5225, lng: 31.4659),
    CountryInfo(code: 'ET', name: 'Ethiopia', flag: '🇪🇹', format: 'CC CCCCC', lat: 9.1450, lng: 40.4897),
    CountryInfo(code: 'GA', name: 'Gabon', flag: '🇬🇦', format: 'LL CCCC', lat: -0.8037, lng: 11.6094),
    CountryInfo(code: 'GM', name: 'Gambia', flag: '🇬🇲', format: 'LL CCCC', lat: 13.4432, lng: -15.3101),
    CountryInfo(code: 'GH', name: 'Ghana', flag: '🇬🇭', format: 'LL CCCC CC', lat: 7.9465, lng: -1.0232),
    CountryInfo(code: 'GN', name: 'Guinea', flag: '🇬🇳', format: 'LL CCCC', lat: 9.9456, lng: -9.6966),
    CountryInfo(code: 'GW', name: 'Guinea-Bissau', flag: '🇬🇼', format: 'L CCCC', lat: 11.8037, lng: -15.1804),
    CountryInfo(code: 'KE', name: 'Kenya', flag: '🇰🇪', format: 'LLL CCC', lat: -0.0236, lng: 37.9062),
    CountryInfo(code: 'LS', name: 'Lesotho', flag: '🇱🇸', format: 'L CCCC', lat: -29.6100, lng: 28.2336),
    CountryInfo(code: 'LR', name: 'Liberia', flag: '🇱🇷', format: 'L CCCC', lat: 6.4281, lng: -9.4295),
    CountryInfo(code: 'LY', name: 'Libya', flag: '🇱🇾', format: 'CCCC L', lat: 26.3351, lng: 17.2283),
    CountryInfo(code: 'MG', name: 'Madagascar', flag: '🇲🇬', format: 'LLL CCCC', lat: -18.7669, lng: 46.8691),
    CountryInfo(code: 'MW', name: 'Malawi', flag: '🇲🇼', format: 'LL CCC', lat: -13.2543, lng: 34.3015),
    CountryInfo(code: 'ML', name: 'Mali', flag: '🇲🇱', format: 'CCCC LL', lat: 17.5707, lng: -3.9962),
    CountryInfo(code: 'MA', name: 'Morocco', flag: '🇲🇦', format: 'CCCC L CC', lat: 31.7917, lng: -7.0926),
    CountryInfo(code: 'MR', name: 'Mauritania', flag: '🇲🇷', format: 'CCCC LL', lat: 21.0079, lng: -10.9408),
    CountryInfo(code: 'MU', name: 'Mauritius', flag: '🇲🇺', format: 'CCCC', lat: -20.3484, lng: 57.5522),
    CountryInfo(code: 'MZ', name: 'Mozambique', flag: '🇲🇿', format: 'LLL CCC', lat: -18.6657, lng: 35.5296),
    CountryInfo(code: 'NA', name: 'Namibia', flag: '🇳🇦', format: 'L CCCC', lat: -22.9576, lng: 18.4904),
    CountryInfo(code: 'NE', name: 'Niger', flag: '🇳🇪', format: 'CCCC LL', lat: 17.6078, lng: 8.0817),
    CountryInfo(code: 'NG', name: 'Nigeria', flag: '🇳🇬', format: 'LLL-CCC-LL', lat: 9.0820, lng: 8.6753),
    CountryInfo(code: 'RW', name: 'Rwanda', flag: '🇷🇼', format: 'LLL CCC', lat: -1.9403, lng: 29.8739),
    CountryInfo(code: 'ST', name: 'São Tomé and Príncipe', flag: '🇸🇹', format: 'L CCC', lat: 0.1864, lng: 6.6131),
    CountryInfo(code: 'SN', name: 'Senegal', flag: '🇸🇳', format: 'LL CCCC L', lat: 14.4974, lng: -14.4524),
    CountryInfo(code: 'SC', name: 'Seychelles', flag: '🇸🇨', format: 'L CCCC', lat: -4.6796, lng: 55.4920),
    CountryInfo(code: 'SL', name: 'Sierra Leone', flag: '🇸🇱', format: 'LLL CCC', lat: 8.4606, lng: -11.7799),
    CountryInfo(code: 'SO', name: 'Somalia', flag: '🇸🇴', format: 'CCCC L', lat: 5.1521, lng: 46.1996),
    CountryInfo(code: 'ZA', name: 'South Africa', flag: '🇿🇦', format: 'LLL CCC XX', lat: -30.5595, lng: 22.9375),
    CountryInfo(code: 'SD', name: 'Sudan', flag: '🇸🇩', format: 'CCCC L', lat: 12.8628, lng: 30.2176),
    CountryInfo(code: 'SS', name: 'South Sudan', flag: '🇸🇸', format: 'L CCCC', lat: 6.8770, lng: 31.3070),
    CountryInfo(code: 'TZ', name: 'Tanzania', flag: '🇹🇿', format: 'LLL CCCC', lat: -6.3690, lng: 34.8888),
    CountryInfo(code: 'TG', name: 'Togo', flag: '🇹🇬', format: 'CCCC LL', lat: 8.6195, lng: 0.8248),
    CountryInfo(code: 'TN', name: 'Tunisia', flag: '🇹🇳', format: 'CCC LLL', lat: 33.8869, lng: 9.5375),
    CountryInfo(code: 'UG', name: 'Uganda', flag: '🇺🇬', format: 'LLL CCC', lat: 1.3733, lng: 32.2903),
    CountryInfo(code: 'ZM', name: 'Zambia', flag: '🇿🇲', format: 'LLL CCC', lat: -13.1339, lng: 27.8493),
    CountryInfo(code: 'ZW', name: 'Zimbabwe', flag: '🇿🇼', format: 'CCC LLL', lat: -19.0154, lng: 29.1549),

    // Australia and Oceania
    CountryInfo(code: 'AU', name: 'Australia', flag: '🇦🇺', format: 'LLL CCC', lat: -25.2744, lng: 133.7751),
    CountryInfo(code: 'FJ', name: 'Fiji', flag: '🇫🇯', format: 'LL CCCC', lat: -16.5781, lng: 179.4144),
    CountryInfo(code: 'KI', name: 'Kiribati', flag: '🇰🇮', format: 'L CCC', lat: -3.3704, lng: -168.7340),
    CountryInfo(code: 'MH', name: 'Marshall Islands', flag: '🇲🇭', format: 'L CCC', lat: 7.1315, lng: 171.1845),
    CountryInfo(code: 'FM', name: 'Micronesia', flag: '🇫🇲', format: 'L CCC', lat: 7.4256, lng: 150.5508),
    CountryInfo(code: 'NR', name: 'Nauru', flag: '🇳🇷', format: 'CCCC', lat: -0.5228, lng: 166.9315),
    CountryInfo(code: 'NZ', name: 'New Zealand', flag: '🇳🇿', format: 'LLLCCC', lat: -40.9006, lng: 174.8860),
    CountryInfo(code: 'PW', name: 'Palau', flag: '🇵🇼', format: 'L CCC', lat: 7.5150, lng: 134.5825),
    CountryInfo(code: 'PG', name: 'Papua New Guinea', flag: '🇵🇬', format: 'L CCCC', lat: -6.3150, lng: 143.9555),
    CountryInfo(code: 'WS', name: 'Samoa', flag: '🇼🇸', format: 'CCCC', lat: -13.7590, lng: -172.1046),
    CountryInfo(code: 'SB', name: 'Solomon Islands', flag: '🇸🇧', format: 'L CCCC', lat: -9.6457, lng: 160.1562),
    CountryInfo(code: 'TO', name: 'Tonga', flag: '🇹🇴', format: 'L CCCC', lat: -21.1789, lng: -175.1982),
    CountryInfo(code: 'TV', name: 'Tuvalu', flag: '🇹🇻', format: 'L CCC', lat: -7.1095, lng: 177.6493),
    CountryInfo(code: 'VU', name: 'Vanuatu', flag: '🇻🇺', format: 'L CCCC', lat: -15.3767, lng: 166.9592),
  ];

  static Future<CountryInfo?> detectCurrentCountry() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      Position position = await Geolocator.getCurrentPosition();
      
      // Find closest country by distance
      CountryInfo? closest;
      double minDistance = double.infinity;

      for (var country in countries) {
        double distance = Geolocator.distanceBetween(
          position.latitude, 
          position.longitude, 
          country.lat, 
          country.lng
        );
        
        if (distance < minDistance) {
          minDistance = distance;
          closest = country;
        }
      }

      return closest;
    } catch (e) {
      print('Error detecting country: $e');
      return null;
    }
  }

  static CountryInfo? getCountryByCode(String code) {
    try {
      return countries.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }

  static List<CountryInfo> searchCountries(String query) {
    if (query.isEmpty) return countries;
    
    query = query.toLowerCase();
    return countries.where((country) => 
      country.name.toLowerCase().contains(query) || 
      country.code.toLowerCase().contains(query)
    ).toList();
  }

  static List<CountryInfo> getAvailableCountries() {
    return List.from(countries);
  }

  static String formatPlateNumber(String input, String format) {
    // Remove all non-alphanumeric characters
    String clean = input.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    
    if (clean.isEmpty) return '';
    
    String result = '';
    int cleanIndex = 0;
    
    for (int i = 0; i < format.length && cleanIndex < clean.length; i++) {
      switch (format[i]) {
        case 'L': // Letter
          if (RegExp(r'[A-Z]').hasMatch(clean[cleanIndex])) {
            result += clean[cleanIndex];
            cleanIndex++;
          }
          break;
        case 'C': // Character (letter or number)
          result += clean[cleanIndex];
          cleanIndex++;
          break;
        case 'N': // Number
          if (RegExp(r'[0-9]').hasMatch(clean[cleanIndex])) {
            result += clean[cleanIndex];
            cleanIndex++;
          }
          break;
        case ' ':
        case '-':
          if (result.isNotEmpty && !result.endsWith(' ') && !result.endsWith('-')) {
            result += format[i];
          }
          break;
      }
    }
    
    return result;
  }
}
