/// Payment apps Qest can launch on the user's behalf.
enum PaymentApp {
  none(label: 'None', androidPackage: null, iosScheme: null, webFallback: null),
  valu(
    label: 'valU',
    androidPackage: 'com.evahcl.valu',
    iosScheme: 'valu://',
    webFallback: 'https://www.valu.com.eg',
  ),
  fawry(
    label: 'Fawry',
    androidPackage: 'com.fawry.fawrypay',
    iosScheme: 'fawry://',
    webFallback: 'https://fawry.com',
  ),
  instapay(
    label: 'InstaPay',
    androidPackage: 'eg.gov.cbe.ipn',
    iosScheme: 'instapay://',
    webFallback: 'https://instapay.eg',
  ),
  vodafoneCash(
    label: 'Vodafone Cash',
    androidPackage: 'com.vodafone.mt.dcb',
    iosScheme: null,
    webFallback: 'https://web.vodafone.com.eg',
  ),
  cib(
    label: 'CIB',
    androidPackage: 'com.cib.mobile',
    iosScheme: null,
    webFallback: 'https://www.cibeg.com',
  ),
  custom(label: 'Custom', androidPackage: null, iosScheme: null, webFallback: null);

  const PaymentApp({
    required this.label,
    required this.androidPackage,
    required this.iosScheme,
    required this.webFallback,
  });

  final String label;
  final String? androidPackage;
  final String? iosScheme;
  final String? webFallback;
}
