import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../features/rule_book/model/legal_document.dart';
import '../shared/services/nepal_law_api.dart';

final lawDocsBoxProvider = FutureProvider<Box<LegalDocument>>((ref) async {
  return Hive.openBox<LegalDocument>('legal_docs');
});

final lawDocsMetaBoxProvider = FutureProvider<Box>((ref) async {
  return Hive.openBox('law_docs_meta');
});

final _lawRefreshLockProvider = StateProvider<bool>((ref) => false);

final lawProvider = FutureProvider<List<LegalDocument>>((ref) async {
  ref.watch(_lawRefreshLockProvider);
  final box = await ref.watch(lawDocsBoxProvider.future);
  final metaBox = await ref.watch(lawDocsMetaBoxProvider.future);

  if (box.isNotEmpty) {
    final isRefreshing = ref.read(_lawRefreshLockProvider);
    if (!isRefreshing) {
      ref.read(_lawRefreshLockProvider.notifier).state = true;
      _backgroundFetchDocs(ref, box, metaBox);
    }
    return box.values.toList();
  }

  final seedDocs = _seedDocuments();
  final map = {for (final doc in seedDocs) doc.id: doc};
  await box.putAll(map);
  await metaBox.put('seeded', true);

  ref.read(_lawRefreshLockProvider.notifier).state = true;
  _backgroundFetchDocs(ref, box, metaBox);
  return seedDocs;
});

void _backgroundFetchDocs(Ref ref, Box<LegalDocument> box, Box metaBox) async {
  try {
    final response = await NepalLawApi.fetchAll();
    if (response.error == null && response.documents.isNotEmpty) {
      final map = {for (final doc in response.documents) doc.id: doc};
      await box.putAll(map);
      await metaBox.put('lastFetched', DateTime.now().toIso8601String());
      await metaBox.put('isOffline', false);
    } else {
      await metaBox.put('isOffline', true);
    }
  } catch (_) {
    await metaBox.put('isOffline', true);
  } finally {
    ref.read(_lawRefreshLockProvider.notifier).state = false;
    ref.invalidate(lawProvider);
  }
}

final lawCategoriesProvider = Provider<Map<String, List<LegalDocument>>>((ref) {
  final docs = ref.watch(lawProvider).valueOrNull ?? [];
  final map = <String, List<LegalDocument>>{};
  for (final doc in docs) {
    map.putIfAbsent(doc.category, () => []).add(doc);
  }
  return map;
});

final lawSearchProvider = Provider.family<List<LegalDocument>, String>((ref, query) {
  if (query.isEmpty) return ref.watch(lawProvider).valueOrNull ?? [];
  final docs = ref.watch(lawProvider).valueOrNull ?? [];
  final q = query.toLowerCase();
  return docs.where((d) =>
    d.titleEn.toLowerCase().contains(q) ||
    d.titleNp.toLowerCase().contains(q) ||
    d.contentEn.toLowerCase().contains(q) ||
    d.contentNp.toLowerCase().contains(q) ||
    d.keywords.any((k) => k.toLowerCase().contains(q))
  ).toList();
});

final lawDocByIdProvider = FutureProvider.family<LegalDocument?, String>((ref, id) async {
  final box = await ref.watch(lawDocsBoxProvider.future);
  return box.get(id);
});

List<LegalDocument> _seedDocuments() {
  return [

    // ===== CONSTITUTION (6) =====
    LegalDocument(
      id: 'const_001',
      titleEn: 'Right to Fundamental Rights',
      titleNp: 'मौलिक हकको अधिकार',
      category: 'Constitution',
      contentEn: 'Every citizen shall have the right to enjoy fundamental rights guaranteed by the Constitution of Nepal. The fundamental rights include the right to equality, right to freedom, right against exploitation, right to religion, right to education and culture, right to health, right to justice, and right to constitutional remedies. No law shall be made that abridges or abrogates the fundamental rights conferred by this Constitution. The State shall not deny to any person equality before the law or equal protection of the laws within the territory of Nepal. All citizens shall be equal before the law. There shall be no discrimination on grounds of religion, race, caste, tribe, sex, origin, language, or ideological conviction. Special provisions may be made by law for the protection, empowerment, or advancement of women, Dalits, indigenous peoples, Madhesis, Tharus, Muslims, oppressed communities, persons with disabilities, and marginalized groups. The right to constitutional remedies enables any citizen to move the Supreme Court for the enforcement of fundamental rights through habeas corpus, mandamus, prohibition, quo warranto, and certiorari writs.',
      contentNp: 'प्रत्येक नागरिकले नेपालको संविधानद्वारा प्रत्याभूत मौलिक हकहरू उपभोग गर्ने अधिकार हुनेछ। मौलिक हकहरूमा समानताको हक, स्वतन्त्रताको हक, शोषणविरुद्धको हक, धार्मिक स्वतन्त्रताको हक, शिक्षा र संस्कृतिको हक, स्वास्थ्यको हक, न्यायको हक र संवैधानिक उपचारको हक समावेश छन्। यस संविधानद्वारा प्रदत्त मौलिक हकहरूको उल्लङ्घन वा खण्डन गर्ने कुनै पनि कानून बनाइने छैन। राज्यले नेपालको भू-भागभित्र कसैलाई पनि कानूनको अगाडि समानताको हक वा कानूनको समान संरक्षणबाट वञ्चित गर्ने छैन। सबै नागरिक कानूनको अगाडि समान हुनेछन्। धर्म, जाति, वर्ण, जातजाति, लिङ्ग, उत्पत्ति, भाषा वा वैचारिक आस्थाको आधारमा कुनै भेदभाव गरिने छैन। महिला, दलित, आदिवासी जनजाति, मधेसी, थारू, मुस्लिम, उत्पीडित समुदाय, अपाङ्गता भएका व्यक्तिहरू र सीमान्तकृत समूहहरूको संरक्षण, सशक्तीकरण वा उत्थानको लागि कानूनद्वारा विशेष व्यवस्था गर्न सकिनेछ। संवैधानिक उपचारको हकले कुनै पनि नागरिकलाई बन्दी प्रत्यक्षीकरण, परमादेश, निषेधाज्ञा, उत्प्रेषण र प्रमाणपत्र जारी गर्ने रिटमार्फत मौलिक हकको कार्यान्वयनको लागि सर्वोच्च अदालत जान सक्षम बनाउँदछ।',
      keywords: ['fundamental rights', 'equality', 'freedom', 'constitution', 'discrimination', 'maulik hak', 'samanta', 'constitutional remedies'],
    ),
    LegalDocument(
      id: 'const_002',
      titleEn: 'Structure of Federal Government',
      titleNp: 'संघीय सरकारको संरचना',
      category: 'Constitution',
      contentEn: 'The Constitution of Nepal establishes a federal democratic republican system with three levels of government: federal, provincial, and local. The federal government consists of the President, Vice-President, the Council of Ministers headed by the Prime Minister, and the Federal Parliament comprising the House of Representatives and the National Assembly. The executive power of Nepal shall be vested in the Council of Ministers. The President is the head of state and exercises ceremonial powers as specified by the Constitution. The Prime Minister is the head of government and exercises executive powers. The Federal Parliament shall have the power to make laws on matters enumerated in the Federal List, including defense, foreign affairs, national security, central banking, citizenship, interstate commerce, and international trade. The House of Representatives consists of 275 members elected through a mixed electoral system combining first-past-the-post and proportional representation. The National Assembly consists of 59 members, including at least three women, one Dalit, and one person with disability.',
      contentNp: 'नेपालको संविधानले संघ, प्रदेश र स्थानीय गरी तीन तहको सरकार भएको संघीय लोकतान्त्रिक गणतन्त्रात्मक प्रणाली स्थापना गरेको छ। संघीय सरकारमा राष्ट्रपति, उपराष्ट्रपति, प्रधानमन्त्रीको नेतृत्वमा रहने मन्त्रीपरिषद्, र प्रतिनिधिसभा र राष्ट्रियसभा मिलेर बनेको संघीय संसद् रहेको छ। नेपालको कार्यकारिणी शक्ति मन्त्रीपरिषद्मा निहित हुनेछ। राष्ट्रपति राज्यको प्रमुख हुनेछन् र संविधानले तोकेबमोजिमको औपचारिक अधिकार प्रयोग गर्नेछन्। प्रधानमन्त्री सरकारको प्रमुख हुनेछन् र कार्यकारी अधिकार प्रयोग गर्नेछन्। संघीय संसद्ले संघीय सूचीमा उल्लेखित विषयहरूमा कानून बनाउने अधिकार हुनेछ, जसमा रक्षा, परराष्ट्र मामिला, राष्ट्रिय सुरक्षा, केन्द्रीय बैंक, नागरिकता, अन्तरप्रदेश व्यापार र अन्तर्राष्ट्रिय व्यापार समावेश छन्। प्रतिनिधिसभामा प्रत्यक्ष निर्वाचन र समानुपातिक प्रतिनिधित्वको मिश्रित निर्वाचन प्रणालीमार्फत निर्वाचित २७५ सदस्य हुन्छन्। राष्ट्रियसभामा कम्तीमा तीन महिला, एक दलित र एक अपाङ्गता भएको व्यक्तिसहित ५९ सदस्य हुन्छन्।',
      keywords: ['federal government', 'president', 'prime minister', 'parliament', 'federal structure', 'sanghiya sarkar', 'constitution', 'council of ministers'],
    ),
    LegalDocument(
      id: 'const_003',
      titleEn: 'Provincial Powers and Autonomy',
      titleNp: 'प्रदेशीय अधिकार र स्वायत्तता',
      category: 'Constitution',
      contentEn: 'Each province in Nepal shall have a Provincial Assembly, a Provincial Council of Ministers headed by a Chief Minister, and a Provincial Head appointed by the President. The province shall have legislative, executive, and financial autonomy within the sphere of its jurisdiction as provided by the Constitution. The Provincial Assembly shall have the power to make laws on matters enumerated in the Provincial List, including provincial police, provincial civil service, agriculture, provincial highways, health services, and education up to secondary level. The province shall have the power to levy taxes on matters within its jurisdiction, including land tax, entertainment tax, and service charges. Any conflict between federal and provincial laws on subjects enumerated in the Concurrent List shall be resolved as per the provisions of the Constitution. The federal law shall prevail in case of conflict on matters of national importance. Provinces also have the right to borrow from financial institutions with federal government guarantees.',
      contentNp: 'नेपालको प्रत्येक प्रदेशमा प्रदेशसभा, मुख्यमन्त्रीको नेतृत्वमा रहने प्रदेश मन्त्रीपरिषद् र राष्ट्रपतिद्वारा नियुक्त प्रदेश प्रमुख रहनेछ। प्रदेशले संविधानले प्रदत्त आफ्नो अधिकारक्षेत्रभित्र विधायिकी, कार्यकारी र वित्तीय स्वायत्तता प्राप्त गर्नेछ। प्रदेशसभाले प्रदेश सूचीमा उल्लेखित विषयहरूमा कानून बनाउने अधिकार हुनेछ, जसमा प्रदेश प्रहरी, प्रदेश निजामती सेवा, कृषि, प्रदेश राजमार्ग, स्वास्थ्य सेवा र माध्यमिक तहसम्मको शिक्षा समावेश छन्। प्रदेशले आफ्नो अधिकारक्षेत्रभित्रको विषयमा कर लगाउने अधिकार हुनेछ, जसमा भूमिकर, मनोरञ्जन कर र सेवा शुल्क समावेश छन्। साझा सूचीमा उल्लेखित विषयहरूमा संघीय र प्रदेश कानूनबीच द्वन्द्व भएमा संविधानको व्यवस्थाबमोजिम समाधान गरिनेछ। राष्ट्रिय महत्त्वका विषयमा द्वन्द्व भएमा संघीय कानून प्रबल हुनेछ। प्रदेशहरूलाई संघीय सरकारको ग्यारेन्टीमा वित्तीय संस्थाहरूबाट ऋण लिने अधिकार पनि हुनेछ।',
      keywords: ['province', 'provincial assembly', 'chief minister', 'autonomy', 'pradesh', 'pradeshsabha', 'concurrent list', 'provincial tax'],
    ),
    LegalDocument(
      id: 'const_004',
      titleEn: 'Right to Freedom of Speech and Expression',
      titleNp: 'वाक् स्वतन्त्रता र अभिव्यक्तिको हक',
      category: 'Constitution',
      contentEn: 'Every citizen shall have the right to freedom of speech and expression, including the right to seek, receive, and impart information and ideas of any nature through any medium. This right includes the freedom of the press and the right to publish and broadcast. However, nothing shall be deemed to prevent the State from making laws imposing reasonable restrictions on this right in the interests of the sovereignty, territorial integrity, national security, public order, decency, morality, or contempt of court, incitement to an offense, or defamation. The press shall be free and no law shall be made that restricts press freedom except in the public interest. The right to information is recognized as a fundamental right, and every citizen shall have the right to access information held by public bodies, subject to conditions as may be provided by law. The electronic and print media have the right to report on matters of public interest without prior censorship.',
      contentNp: 'प्रत्येक नागरिकलाई वाक् स्वतन्त्रता र अभिव्यक्तिको हक हुनेछ, जसमा कुनै पनि माध्यमबाट कुनै पनि प्रकृतिको सूचना र विचार खोज्ने, प्राप्त गर्ने र प्रदान गर्ने अधिकार समावेश छ। यस हकमा प्रेस स्वतन्त्रता र प्रकाशन तथा प्रसारण गर्ने अधिकार समावेश छ। तथापि, राज्यले सार्वभौमिकता, भू-अखण्डता, राष्ट्रिय सुरक्षा, सार्वजनिक व्यवस्था, शालीनता, नैतिकता, वा अदालतको अवहेलना, अपराध गर्न उक्साउने वा मानहानिको हितमा यस हकमा उचित प्रतिबन्ध लगाउने कानून बनाउनबाट कसैले रोक्ने छैन। प्रेस स्वतन्त्र हुनेछ र सार्वजनिक हितबाहेक प्रेस स्वतन्त्रतालाई प्रतिबन्ध लगाउने कुनै कानून बनाइने छैन। सूचनाको हकलाई मौलिक हकको रूपमा मान्यता दिइएको छ र प्रत्येक नागरिकलाई कानूनले निर्धारण गरेको शर्तहरूको अधीनमा रही सार्वजनिक निकायहरूसँग रहेको सूचनामा पहुँच पाउने हक हुनेछ। इलेक्ट्रोनिक र प्रिन्ट मिडियालाई पूर्व सेन्सरशिपविना सार्वजनिक हितका विषयहरूमा रिपोर्ट गर्ने अधिकार छ।',
      keywords: ['freedom of speech', 'expression', 'press freedom', 'right to information', 'vak swatantrata', 'abhivyakti', 'media', 'defamation'],
    ),
    LegalDocument(
      id: 'const_005',
      titleEn: 'Directive Principles and State Policies',
      titleNp: 'राज्यका निर्देशक सिद्धान्त र नीतिहरू',
      category: 'Constitution',
      contentEn: 'The Directive Principles and State Policies of the Constitution of Nepal serve as the fundamental guiding principles for the governance of the country. The State shall pursue a policy of establishing an egalitarian society based on the principles of justice, liberty, and equality. The State shall be committed to the progressive enhancement of the people welfare and the protection of their rights. The State shall pursue policies that promote sustainable development, poverty alleviation, and equitable distribution of resources. Special emphasis shall be placed on the inclusion of marginalized, oppressed, and vulnerable communities in all aspects of national life. The State shall give priority to the protection and promotion of the national language, culture, arts, and heritage. While these principles are not directly enforceable in any court, they are fundamental to the governance of the country and it shall be the duty of the State to apply them in making laws and implementing policies.',
      contentNp: 'नेपालको संविधानका राज्यका निर्देशक सिद्धान्त र नीतिहरू देशको शासनका लागि आधारभूत मार्गदर्शक सिद्धान्तको रूपमा काम गर्दछन्। राज्यले न्याय, स्वतन्त्रता र समानताका सिद्धान्तहरूमा आधारित समतामूलक समाज स्थापना गर्ने नीति अवलम्बन गर्नेछ। राज्य जनताको कल्याण र उनीहरूको अधिकारको संरक्षणको क्रमिक अभिवृद्धिका लागि प्रतिबद्ध हुनेछ। राज्यले दिगो विकास, गरिबी निवारण र स्रोतसाधनको समुचित वितरणलाई प्रवर्धन गर्ने नीति अवलम्बन गर्नेछ। राष्ट्रिय जीवनका सबै पक्षहरूमा सीमान्तकृत, उत्पीडित र कमजोर समुदायहरूको समावेशीकरणमा विशेष जोड दिइनेछ। राज्यले राष्ट्रिय भाषा, संस्कृति, कला र सम्पदाको संरक्षण र प्रवर्धनलाई प्राथमिकता दिनेछ। यी सिद्धान्तहरू कुनै अदालतमा प्रत्यक्ष रूपमा लागू गर्न नसकिने भए तापनि तिनीहरू देशको शासनका लागि आधारभूत छन् र कानून निर्माण र नीति कार्यान्वयनमा तिनीहरूलाई लागू गर्नु राज्यको कर्तव्य हुनेछ।',
      keywords: ['directive principles', 'state policy', 'nirdeshak siddhanta', 'egalitarian society', 'poverty alleviation', 'sustainable development', 'inclusion', 'social justice'],
    ),
    LegalDocument(
      id: 'const_006',
      titleEn: 'Citizenship Provisions',
      titleNp: 'नागरिकताको व्यवस्था',
      category: 'Constitution',
      contentEn: 'The Constitution of Nepal provides for the acquisition, termination, and re-acquisition of citizenship. Citizenship may be acquired by descent, by birth, or by naturalization. A person born to a Nepali citizen father and mother shall acquire citizenship by descent. A person born in Nepal to a Nepali mother and an unknown father, or to parents who are stateless, shall acquire citizenship by birth. Foreign women married to Nepali citizens may acquire naturalized citizenship as provided by federal law. The Government of Nepal may grant honorary citizenship to distinguished foreign nationals. Citizenship certificates shall be issued by the Government of Nepal. Citizens shall have the right to obtain a passport and other travel documents. No citizen shall be denied the right to enter, remain in, or leave Nepal except as provided by law. Dual citizenship is not permitted in Nepal, but provisions may be made for non-resident Nepali status for former citizens who have acquired foreign citizenship.',
      contentNp: 'नेपालको संविधानले नागरिकता प्राप्ति, समाप्ति र पुनः प्राप्तिको व्यवस्था गरेको छ। नागरिकता वंशजद्वारा, जन्मद्वारा वा प्राकृतिकीकरणद्वारा प्राप्त गर्न सकिन्छ। नेपाली नागरिक बाबु र आमाबाट जन्मेको व्यक्तिले वंशजको आधारमा नागरिकता प्राप्त गर्नेछ। नेपाली आमा र अज्ञात बाबु, वा राज्यविहीन आमाबाबुबाट नेपालमा जन्मेको व्यक्तिले जन्मको आधारमा नागरिकता प्राप्त गर्नेछ। नेपाली नागरिकसँग विवाह गरेकी विदेशी महिलाले संघीय कानूनले व्यवस्था गरेबमोजिम प्राकृतिकीकृत नागरिकता प्राप्त गर्न सक्नेछन्। नेपाल सरकारले विशिष्ट विदेशी नागरिकहरूलाई मानार्थ नागरिकता प्रदान गर्न सक्नेछ। नागरिकताको प्रमाणपत्र नेपाल सरकारले जारी गर्नेछ। नागरिकहरूलाई राहदानी र अन्य यात्रा कागजात प्राप्त गर्ने अधिकार हुनेछ। कानूनले व्यवस्था गरेको बाहेक कुनै पनि नागरिकलाई नेपाल प्रवेश गर्ने, बस्ने वा छोड्ने अधिकारबाट वञ्चित गरिने छैन। नेपालमा दोहोरो नागरिकताको अनुमति छैन, तर विदेशी नागरिकता प्राप्त गरेका पूर्व नागरिकहरूको लागि गैर-आवासीय नेपालीको स्थितिको व्यवस्था गर्न सकिनेछ।',
      keywords: ['citizenship', 'naturalization', 'passport', 'non-resident Nepali', 'nagarikata', 'descent', 'birth', 'honorary citizenship'],
    ),

    // ===== CIVIL LAW (7) =====
    LegalDocument(
      id: 'civil_001',
      titleEn: 'Contract Formation and Validity',
      titleNp: 'सम्झौता गठन र वैधता',
      category: 'Civil Law',
      contentEn: 'A contract is an agreement between two or more parties that creates legally binding obligations. For a contract to be valid, it must contain an offer, acceptance of that offer, lawful consideration, and the intention to create legal relations. Both parties must have the capacity to contract, meaning they must be of the age of majority, of sound mind, and not disqualified by law. Consent must be free, not obtained through coercion, undue influence, fraud, misrepresentation, or mistake. The subject matter of the contract must be lawful and not contrary to public policy. A contract in writing is not always necessary, but certain contracts such as those relating to immovable property, marriage settlements, and agreements that cannot be performed within one year must be in writing and registered. If a contract is void, it has no legal effect from the beginning. A voidable contract remains valid until the party entitled to avoid it exercises that right.',
      contentNp: 'सम्झौता दुई वा दुईभन्दा बढी पक्षहरूबीचको सहमति हो जसले कानूनी रूपमा बाध्यकारी दायित्वहरू सिर्जना गर्दछ। सम्झौता वैध हुनको लागि यसमा प्रस्ताव, त्यस प्रस्तावको स्वीकृति, वैध प्रतिफल, र कानूनी सम्बन्ध सिर्जना गर्ने आशय हुनुपर्दछ। दुवै पक्षहरूमा सम्झौता गर्ने क्षमता हुनुपर्दछ, अर्थात् तिनीहरू वयस्क उमेरका, सचेत मनका, र कानूनद्वारा अयोग्य नभएका हुनुपर्दछ। सहमति स्वतन्त्र हुनुपर्दछ, जबरजस्ती, अनुचित प्रभाव, धोखाधडी, गलत बयान वा गल्तीबाट प्राप्त गरिएको हुनुहुँदैन। सम्झौताको विषय वस्तु कानूनी हुनुपर्दछ र सार्वजनिक नीतिको विपरीत हुनुहुँदैन। लिखित सम्झौता सधैं आवश्यक हुँदैन, तर स्थावर सम्पत्ति, विवाह बन्डोस्ती, र एक वर्षभित्र पूरा नहुने सम्झौताहरू लिखित र दर्ता हुनुपर्दछ। यदि सम्झौता शून्य छ भने, यसको सुरुदेखि नै कुनै कानूनी प्रभाव हुँदैन। शून्यकरणीय सम्झौता तबसम्म वैध रहन्छ जबसम्म यसलाई बेवास्ता गर्न हकदार पक्षले त्यो अधिकार प्रयोग गर्दैन।',
      keywords: ['contract', 'offer', 'acceptance', 'consideration', 'void agreement', 'samjhauta', 'pratiphal', 'capacity to contract'],
    ),
    LegalDocument(
      id: 'civil_002',
      titleEn: 'Property Inheritance and Succession',
      titleNp: 'सम्पत्ति उत्तराधिकार र हकवाला',
      category: 'Civil Law',
      contentEn: 'The inheritance of property in Nepal is governed by the Muluki Ain (Country Code) 2074, specifically the chapter on inheritance and succession. Upon the death of a person, his or her property devolves to the heirs according to the rules of succession. Heirs are classified into different classes based on their relationship to the deceased. The surviving spouse, children, and parents are primary heirs. Sons and daughters have equal rights to inherit ancestral property. A person may dispose of his or her self-acquired property through a will or testament. A testator must be of sound mind and at least eighteen years of age to make a valid will. The will must be in writing, signed by the testator, and attested by two witnesses. If a person dies without making a will, the property is distributed according to the laws of intestate succession. A legal heir may renounce his or her share of inheritance by executing a deed of renunciation.',
      contentNp: 'नेपालमा सम्पत्तिको उत्तराधिकार मुलुकी ऐन २०७४, विशेषगरी उत्तराधिकार र हकवालासम्बन्धी परिच्छेदद्वारा नियमन गरिन्छ। कुनै व्यक्तिको मृत्यु भएपछि उसको सम्पत्ति उत्तराधिकारको नियमअनुसार हकवालाहरूमा हस्तान्तरण हुन्छ। हकवालाहरूलाई मृतकसँगको सम्बन्धको आधारमा विभिन्न श्रेणीमा वर्गीकरण गरिन्छ। जीवित जीवनसाथी, सन्तान र आमाबाबु प्राथमिक हकवाला हुन्। छोरा र छोरीलाई पुर्खौली सम्पत्तिमा समान अधिकार हुन्छ। व्यक्तिले आफ्नो आर्जित सम्पत्ति वसीयत वा इच्छापत्रद्वारा व्यवस्थित गर्न सक्छ। वसीयत गर्ने व्यक्ति सचेत मनको र कम्तीमा अठार वर्ष उमेरको हुनुपर्दछ। वसीयत लिखित, वसीयतकर्ताद्वारा हस्ताक्षरित र दुई साक्षीद्वारा प्रमाणित हुनुपर्दछ। यदि व्यक्ति वसीयत नगरी मर्छ भने, सम्पत्ति नियमानुसारको उत्तराधिकारको कानूनअनुसार बाँडिन्छ। कानूनी हकवालाले त्यागपत्र कार्यान्वयन गरी आफ्नो हकको हिस्सा त्याग गर्न सक्छ।',
      keywords: ['inheritance', 'succession', 'will', 'testament', 'uttaradhikar', 'hakwala', 'muluki ain', 'intestate succession'],
    ),
    LegalDocument(
      id: 'civil_003',
      titleEn: 'Marriage and Divorce Law',
      titleNp: 'विवाह र सम्बन्धविच्छेद कानून',
      category: 'Civil Law',
      contentEn: 'Marriage in Nepal is governed by the Muluki Ain and specific marriage registration acts. A marriage is considered valid when both parties have attained the age of twenty years for males and twenty years for females, have given free consent, and are not within prohibited degrees of relationship. Marriage may be solemnized according to religious rites or through a civil ceremony. All marriages must be registered with the concerned government authority within thirty-five days of the ceremony. A spouse may file for divorce on grounds including mutual consent, adultery, cruelty, desertion for three years, mental illness for five years, or if the spouse has been missing for five years. The court may order alimony for the spouse and child support for minor children, taking into consideration the financial status of both parties and the needs of the children. Custody of children is determined based on the best interests of the child, with preference for the mother for children under five years.',
      contentNp: 'नेपालमा विवाह मुलुकी ऐन र विशेष विवाह दर्ता सम्बन्धी कानूनहरूद्वारा नियमन गरिन्छ। विवाह वैध मानिनको लागि दुवै पक्षको उमेर पुरुषको लागि बीस वर्ष र महिलाको लागि बीस वर्ष पुगेको, स्वतन्त्र सहमति प्राप्त भएको, र तिनीहरू निषेधित नाता सम्बन्धभित्र नपरेको हुनुपर्दछ। विवाह धार्मिक संस्कारअनुसार वा नागरिक विवाहको रूपमा सम्पन्न गर्न सकिन्छ। सबै विवाह समारोहको पैंतिस दिनभित्र सम्बन्धित सरकारी निकायमा दर्ता गराउनुपर्दछ। जीवनसाथीले आपसी सहमति, व्यभिचार, क्रूरता, तीन वर्षसम्म परित्याग, पाँच वर्षको मानसिक रोग, वा जीवनसाथी पाँच वर्षदेखि बेपत्ता भएको जस्ता आधारहरूमा सम्बन्धविच्छेदको लागि मुद्दा दायर गर्न सक्छ। अदालतले दुवै पक्षको आर्थिक स्थिति र सन्तानको आवश्यकतालाई ध्यानमा राखी जीवनसाथीको लागि भरणपोषण र नाबालिग सन्तानको लागि सन्तान भत्ताको आदेश दिन सक्छ। सन्तानको संरक्षकत्व सन्तानको सर्वोत्तम हितको आधारमा निर्धारण गरिन्छ, जसमा पाँच वर्षमुनिका सन्तानको लागि आमालाई प्राथमिकता दिइन्छ।',
      keywords: ['marriage', 'divorce', 'alimony', 'child custody', 'registration', 'bibah', 'sambandhabichhed', 'mutual consent'],
    ),
    LegalDocument(
      id: 'civil_004',
      titleEn: 'Law of Torts and Damages',
      titleNp: 'अपकृत्य कानून र क्षतिपूर्ति',
      category: 'Civil Law',
      contentEn: 'A tort is a civil wrong that causes harm or loss to another person, giving rise to a legal liability for damages. The law of torts in Nepal is based on principles of common law and statutory provisions. Key torts include negligence, trespass, nuisance, defamation, and strict liability. To establish negligence, the plaintiff must prove that the defendant owed a duty of care, breached that duty, and caused damage as a direct result of the breach. Defamation involves the publication of a false statement that harms the reputation of another person. Nuisance is the unlawful interference with a person use or enjoyment of their property. The amount of damages awarded depends on the extent of harm, the nature of the wrong, and the circumstances of the case. Courts may award compensatory damages for actual loss, and punitive damages in cases of gross negligence or malicious conduct. The limitation period for filing a tort action is generally one to three years from the date the cause of action arose.',
      contentNp: 'अपकृत्य एक नागरिक गल्ती हो जसले अर्को व्यक्तिलाई हानि वा नोक्सानी पुर्याउँछ, जसले गर्दा क्षतिपूर्तिको लागि कानूनी दायित्व उत्पन्न हुन्छ। नेपालमा अपकृत्यको कानून सामान्य कानून र वैधानिक व्यवस्थाहरूको सिद्धान्तमा आधारित छ। मुख्य अपकृत्यहरूमा लापरवाही, अतिक्रमण, उपद्रव, मानहानि र कडा दायित्व समावेश छन्। लापरवाही स्थापित गर्न, वादीले प्रतिवादीले हेरचाहको कर्तव्य पालना गर्नुपर्ने, त्यो कर्तव्य उल्लङ्घन गरेको, र उक्त उल्लङ्घनको प्रत्यक्ष परिणामस्वरूप क्षति पुगेको प्रमाणित गर्नुपर्दछ। मानहानिले अर्को व्यक्तिको प्रतिष्ठालाई हानि पुर्याउने झूटो कथनको प्रकाशनलाई समावेश गर्दछ। उपद्रव भनेको कुनै व्यक्तिको आफ्नो सम्पत्तिको प्रयोग वा उपभोगमा गैरकानूनी हस्तक्षेप हो। क्षतिपूर्तिको रकम हानिको हद, गल्तीको प्रकृति र मुद्दाको परिस्थितिअनुसार निर्धारण गरिन्छ। अदालतले वास्तविक हानिको लागि प्रतिकारात्मक क्षतिपूर्ति, र गम्भीर लापरवाही वा दुर्भावनापूर्ण आचरणको अवस्थामा दण्डात्मक क्षतिपूर्ति प्रदान गर्न सक्छ। अपकृत्यको मुद्दा दायर गर्नको लागि सीमा अवधि सामान्यतः कार्यको कारण उत्पन्न भएको मितिदेखि एक देखि तीन वर्ष हुन्छ।',
      keywords: ['tort', 'negligence', 'defamation', 'damages', 'trespass', 'apakritya', 'nuisance', 'compensation'],
    ),
    LegalDocument(
      id: 'civil_005',
      titleEn: 'Landlord and Tenant Law',
      titleNp: 'जग्गाधनी र भाडावाल कानून',
      category: 'Civil Law',
      contentEn: 'The relationship between landlords and tenants in Nepal is governed by the Muluki Ain and relevant tenancy acts. A lease agreement for immovable property should be in writing, specifying the rent amount, duration of tenancy, terms of use, and obligations of both parties. The landlord is responsible for ensuring the property is habitable and for major repairs, while the tenant is responsible for maintaining the property in good condition and paying rent on time. Rent increases are regulated and must be reasonable, with prior notice. A tenant cannot sublet the property without the landlord written consent. The landlord may terminate the tenancy for non-payment of rent for three consecutive months, unauthorized alterations to the property, using the property for illegal purposes, or expiration of the lease term. A minimum notice period of thirty days is required for termination. The tenant may also terminate the lease by giving proper notice. Upon termination, the tenant must vacate the premises and restore possession to the landlord.',
      contentNp: 'नेपालमा जग्गाधनी र भाडावालबीचको सम्बन्ध मुलुकी ऐन र सम्बन्धित भाडा ऐनहरूद्वारा नियमन गरिन्छ। स्थावर सम्पत्तिको लागि भाडा सम्झौता लिखित हुनुपर्दछ, जसमा भाडा रकम, भाडाको अवधि, प्रयोगका सर्तहरू र दुवै पक्षका दायित्वहरू उल्लेख गरिएको हुनुपर्दछ। जग्गाधनीले सम्पत्ति बस्न योग्य रहेको सुनिश्चित गर्न र प्रमुख मर्मतका लागि जिम्मेवार हुन्छ, जबकि भाडावालले सम्पत्ति राम्रो अवस्थामा राख्न र समयमै भाडा तिर्न जिम्मेवार हुन्छ। भाडा वृद्धि नियमन गरिएको छ र पूर्व सूचनासहित उचित हुनुपर्दछ। भाडावालले जग्गाधनीको लिखित सहमतिविना सम्पत्ति उपभाडामा दिन सक्दैन। जग्गाधनीले लगातार तीन महिनासम्म भाडा नतिरेमा, सम्पत्तिमा अनधिकृत परिवर्तन गरेमा, सम्पत्ति गैरकानूनी उद्देश्यका लागि प्रयोग गरेमा, वा भाडा अवधि समाप्त भएमा भाडावालको भाडा समाप्त गर्न सक्छ। समाप्तिको लागि कम्तीमा तीस दिनको सूचना अवधि आवश्यक हुन्छ। भाडावालले पनि उचित सूचना दिएर भाडा समाप्त गर्न सक्छ। समाप्तिपछि, भाडावालले परिसर खाली गरी जग्गाधनीलाई कब्जा फिर्ता गर्नुपर्दछ।',
      keywords: ['landlord', 'tenant', 'lease', 'rent', 'eviction', 'jaggadhani', 'bhadawal', 'sublease'],
    ),
    LegalDocument(
      id: 'civil_006',
      titleEn: 'Limitation Act for Civil Claims',
      titleNp: 'देवानी दाबीको लागि सीमा अवधि ऐन',
      category: 'Civil Law',
      contentEn: 'The Limitation Act establishes the time periods within which legal proceedings must be initiated in civil matters. The purpose of limitation periods is to ensure certainty in legal affairs, prevent stale claims, and protect defendants from being prejudiced by delay. The general limitation period for civil claims is three years from the date the cause of action arose. For claims relating to immovable property, the limitation period is twelve years for recovery of possession. For contracts, the limitation period is six years for registered contracts and three years for unregistered contracts. Claims for personal injury must be filed within one year, while defamation claims must be filed within six months. The limitation period for recovery of loans is three years from the date the loan became due. Filing an acknowledgment of liability in writing extends the limitation period. When computing limitation periods, the time during which the plaintiff was under a disability, such as minority or unsoundness of mind, is excluded. A court may condone delay on sufficient cause shown.',
      contentNp: 'सीमा अवधि ऐनले देवानी मामिलाहरूमा कानूनी कारबाही सुरु गर्नुपर्ने समयावधि स्थापित गर्दछ। सीमा अवधिको उद्देश्य कानूनी मामिलाहरूमा निश्चितता सुनिश्चित गर्नु, पुराना दाबीहरू रोक्नु र प्रतिवादीहरूलाई ढिलाइले हुन सक्ने हानिबाट संरक्षण गर्नु हो। देवानी दाबीहरूको लागि सामान्य सीमा अवधि कार्यको कारण उत्पन्न भएको मितिदेखि तीन वर्ष हुन्छ। स्थावर सम्पत्तिसँग सम्बन्धित दाबीहरूको लागि, कब्जा फिर्ता पाउनको लागि सीमा अवधि बाह्र वर्ष हुन्छ। सम्झौताको लागि, दर्ता गरिएको सम्झौताको लागि सीमा अवधि छ वर्ष र दर्ता नगरिएको सम्झौताको लागि तीन वर्ष हुन्छ। व्यक्तिगत चोटको दाबी एक वर्षभित्र दायर गर्नुपर्दछ, जबकि मानहानिको दाबी छ महिनाभित्र दायर गर्नुपर्दछ। ऋणको असुलीको लागि सीमा अवधि ऋण बक्यौता भएको मितिदेखि तीन वर्ष हुन्छ। लिखित रूपमा दायित्व स्वीकार गरेको सीमा अवधिलाई विस्तार गर्दछ। सीमा अवधि गणना गर्दा, वादी नाबालिग वा अस्वस्थ मनको जस्तो असमर्थतामा रहेको समय बहिष्कृत गरिन्छ। अदालतले पर्याप्त कारण देखाएमा ढिलाइलाई माफ गर्न सक्छ।',
      keywords: ['limitation', 'limitation period', 'stale claim', 'sima awadhi', 'civil procedure', 'extension', 'acknowledgment', 'disability'],
    ),
    LegalDocument(
      id: 'civil_007',
      titleEn: 'Consumer Protection and Product Liability',
      titleNp: 'उपभोक्ता संरक्षण र उत्पादन दायित्व',
      category: 'Civil Law',
      contentEn: 'The Consumer Protection Act of Nepal provides rights to consumers and establishes mechanisms for the protection of those rights. Every consumer has the right to quality goods and services at reasonable prices, the right to information about the quality, quantity, and price of goods and services, the right to choose from a variety of products, the right to safety against hazardous goods, and the right to seek redressal against unfair trade practices. Sellers and manufacturers are liable for defects in products and deficiencies in services. A consumer may file a complaint with the Consumer Protection Council or the appropriate court for compensation. The act prohibits misleading advertisements, false representations, black marketing, hoarding, and profiteering. Punishments for violations include fines, imprisonment, and compensation orders. Product liability extends to manufacturers, distributors, and sellers for harm caused by defective products. The burden of proof in product liability cases rests on the manufacturer to show that the product was not defective.',
      contentNp: 'नेपालको उपभोक्ता संरक्षण ऐनले उपभोक्ताहरूलाई अधिकार प्रदान गर्दछ र ती अधिकारहरूको संरक्षणको लागि संयन्त्र स्थापित गर्दछ। प्रत्येक उपभोक्तालाई उचित मूल्यमा गुणस्तरीय वस्तु र सेवा पाउने हक, वस्तु र सेवाको गुणस्तर, परिमाण र मूल्यको बारेमा जानकारी पाउने हक, विविध उत्पादनहरूमध्ये छनौट गर्ने हक, खतरनाक वस्तुहरूविरुद्ध सुरक्षाको हक, र अनुचित व्यापार अभ्यासहरूविरुद्ध उपचारको हक हुन्छ। विक्रेता र उत्पादकहरू उत्पादनमा रहेको त्रुटि र सेवामा रहेको कमीको लागि उत्तरदायी हुन्छन्। उपभोक्ताले उपभोक्ता संरक्षण परिषद् वा उपयुक्त अदालतमा क्षतिपूर्तिको लागि उजुरी दिन सक्छ। ऐनले भ्रामक विज्ञापन, झूटो प्रतिनिधित्व, कालोबजारी, मौज्दात र मुनाफाखोरीलाई निषेध गर्दछ। उल्लङ्घनको लागि सजायमा जरिवाना, कैद र क्षतिपूर्ति आदेश समावेश छन्। उत्पादन दायित्व त्रुटिपूर्ण उत्पादनले हुने हानिको लागि उत्पादक, वितरक र विक्रेतासम्म विस्तारित हुन्छ। उत्पादन दायित्वको मुद्दामा प्रमाणको भार उत्पादकमा हुन्छ कि उत्पादन त्रुटिपूर्ण थिएन भनी देखाउन।',
      keywords: ['consumer protection', 'product liability', 'false advertisement', 'black marketing', 'upabhokta', 'complaint', 'compensation', 'quality goods'],
    ),

    // ===== CRIMINAL LAW (7) =====
    LegalDocument(
      id: 'crim_001',
      titleEn: 'Offenses Against the Person',
      titleNp: 'व्यक्तिविरुद्धको अपराध',
      category: 'Criminal Law',
      contentEn: 'Offenses against the person include homicide, assault, battery, kidnapping, and offenses relating to sexual violence. Homicide is classified as murder, manslaughter, or culpable homicide not amounting to murder. Murder is the unlawful killing of a person with malice aforethought, punishable by life imprisonment or death in the most severe cases. Manslaughter is the unlawful killing without malice, which may be voluntary or involuntary. Assault is any act that intentionally causes another person to apprehend immediate unlawful violence. Battery involves the actual infliction of unlawful force on another person. Kidnapping involves taking a person away by force or fraud without their consent. These offenses are investigated by the Nepal Police and prosecuted by the government. The severity of punishment depends on the nature and gravity of the offense, the intent of the offender, and the circumstances surrounding the offense. Self-defense is a valid defense if the force used was proportionate to the threat.',
      contentNp: 'व्यक्तिविरुद्धको अपराधमा हत्या, प्रहार, कुटपिट, अपहरण र यौन हिंसासम्बन्धी अपराधहरू समावेश छन्। हत्यालाई ज्यान मार्ने, गैरइरादात्मक हत्या वा हत्याबराबर नहुने दोषी मानव वधको रूपमा वर्गीकृत गरिन्छ। ज्यान मार्नु भनेको पूर्वयोजनासहित कसैको अवैध हत्या हो, जसको लागि जन्मकैद वा अति गम्भीर अवस्थामा मृत्युदण्डको सजाय हुन सक्छ। गैरइरादात्मक हत्या दुर्भावनाविना भएको अवैध हत्या हो, जुन स्वैच्छिक वा अनैच्छिक हुन सक्छ। प्रहार भनेको कुनै कार्य हो जसले जानीबुझी अर्को व्यक्तिलाई तत्काल अवैध हिंसाको डर महसुस गराउँदछ। कुटपिटमा अर्को व्यक्तिमाथि अवैध बलको प्रयोग समावेश हुन्छ। अपहरणमा व्यक्तिलाई उसको सहमतिविना बल वा धोकाबाट लगी लुकाउने कार्य समावेश हुन्छ। यी अपराधहरूको नेपाल प्रहरीद्वारा अनुसन्धान गरिन्छ र सरकारद्वारा अभियोजन गरिन्छ। सजायको गम्भीरता अपराधको प्रकृति, अपराधीको आशय र अपराधको परिस्थितिमा निर्भर गर्दछ। आत्मरक्षा एक वैध बचाउ हो यदि प्रयोग गरिएको बल खतराको अनुपातमा थियो भने।',
      keywords: ['homicide', 'murder', 'assault', 'kidnapping', 'self-defense', 'hatya', 'manslaughter', 'culpable homicide'],
    ),
    LegalDocument(
      id: 'crim_002',
      titleEn: 'Offenses Against Property',
      titleNp: 'सम्पत्तिविरुद्धको अपराध',
      category: 'Criminal Law',
      contentEn: 'Offenses against property include theft, robbery, burglary, extortion, criminal trespass, and mischief. Theft involves the dishonest taking of movable property without the owner consent with the intent to permanently deprive the owner of it. Robbery is theft combined with the use of force or the threat of force against the victim. Burglary involves entering a building as a trespasser with the intent to commit theft, assault, or criminal damage. Extortion involves obtaining property or money through coercion or threats. Criminal trespass involves entering someone property without lawful authority. Under Nepalese law, these offenses are defined in the Muluki Ain and the Criminal Code Act. The punishment for these offenses ranges from fines to imprisonment, depending on the value of the property involved and the manner of commission. Repeat offenders are subject to enhanced penalties. Restitution of stolen property or compensation to the victim may be ordered.',
      contentNp: 'सम्पत्तिविरुद्धको अपराधमा चोरी, लुटपाट, सेंधमारी, जबरजस्ती असुली, आपराधिक अतिक्रमण र दुराचार समावेश छन्। चोरीमा मालिकको सहमतिविना उसलाई स्थायी रूपमा वञ्चित गर्ने आशयले चल सम्पत्ति बेइमानीपूर्वक लैजाने कार्य समावेश हुन्छ। लुटपाट भनेको पीडितविरुद्ध बल प्रयोग वा बल प्रयोगको धम्कीसहितको चोरी हो। सेंधमारीमा चोरी, प्रहार वा आपराधिक क्षति गर्ने आशयले अतिक्रमणकारीको रूपमा भवनमा प्रवेश गर्ने कार्य समावेश हुन्छ। जबरजस्ती असुलीमा जबरजस्ती वा धम्कीद्वारा सम्पत्ति वा पैसा प्राप्त गर्ने कार्य समावेश हुन्छ। आपराधिक अतिक्रमणमा कानूनी अधिकारविना कसैको सम्पत्तिमा प्रवेश गर्ने कार्य समावेश हुन्छ। नेपाली कानूनअनुसार, यी अपराधहरू मुलुकी ऐन र फौजदारी संहिता ऐनमा परिभाषित छन्। यी अपराधहरूको सजाय सम्पत्तिको मूल्य र अपराध गर्ने तरिकामा निर्भर गर्दै जरिवानादेखि कैदसम्म हुन सक्छ। पुनरावृत्ति अपराधीहरू बढी सजायको भागीदार हुन्छन्। चोरी भएको सम्पत्ति फिर्ता वा पीडितलाई क्षतिपूर्तिको आदेश दिन सकिन्छ।',
      keywords: ['theft', 'robbery', 'burglary', 'extortion', 'chori', 'lutpat', 'criminal trespass', 'property crime'],
    ),
    LegalDocument(
      id: 'crim_003',
      titleEn: 'Cyber Crimes and Digital Offenses',
      titleNp: 'साइबर अपराध र डिजिटल अपराध',
      category: 'Criminal Law',
      contentEn: 'Cyber crimes in Nepal are governed by the Electronic Transactions Act and the Criminal Code Act. These acts address a wide range of digital offenses including unauthorized access to computer systems, hacking, cyber fraud, identity theft, data theft, and the distribution of malicious software. Hacking is defined as intentionally accessing a computer system without authorization with the intent to commit an offense. Cyber fraud involves the use of electronic means to deceive individuals or organizations for financial gain. Identity theft involves using another person personal information without authorization to commit fraud or other crimes. The dissemination of obscene or indecent material through electronic means is a punishable offense. Social media crimes including cyberstalking, cyberbullying, and online harassment are specifically addressed. The punishment for cyber crimes ranges from fines of up to five hundred thousand rupees to imprisonment of up to five years, or both. The Nepal Police Cyber Bureau is the primary agency for investigating cyber crimes.',
      contentNp: 'नेपालमा साइबर अपराधहरू विद्युतीय कारोबार ऐन र फौजदारी संहिता ऐनद्वारा नियमन गरिन्छ। यी ऐनहरूले कम्प्युटर प्रणालीमा अनाधिकृत पहुँच, ह्याकिङ, साइबर ठगी, पहिचान चोरी, डाटा चोरी र मालिसियस सफ्टवेरको वितरण लगायत विभिन्न डिजिटल अपराधहरूलाई सम्बोधन गर्दछ। ह्याकिङलाई अपराध गर्ने आशयले अनाधिकृत रूपमा कम्प्युटर प्रणालीमा जानीबुझी पहुँच प्राप्त गर्ने कार्यको रूपमा परिभाषित गरिएको छ। साइबर ठगीमा आर्थिक लाभको लागि व्यक्ति वा संस्थालाई ठग्न विद्युतीय माध्यमको प्रयोग समावेश हुन्छ। पहिचान चोरीमा ठगी वा अन्य अपराध गर्नको लागि अर्को व्यक्तिको व्यक्तिगत जानकारी अनाधिकृत रूपमा प्रयोग गर्ने कार्य समावेश हुन्छ। विद्युतीय माध्यमबाट अश्लील वा अभद्र सामग्री प्रसार गर्नु दण्डनीय अपराध हो। साइबर स्टकिङ, साइबर बुलिङ र अनलाइन उत्पीडन सहितका सामाजिक सञ्जल अपराधहरूलाई विशेष रूपमा सम्बोधन गरिएको छ। साइबर अपराधको सजाय पाँच लाख रुपैयाँसम्म जरिवाना देखि पाँच वर्षसम्म कैद वा दुवै हुन सक्छ। नेपाल प्रहरीको साइबर ब्युरो साइबर अपराधहरूको अनुसन्धानको लागि प्रमुख निकाय हो।',
      keywords: ['cyber crime', 'hacking', 'identity theft', 'cyber fraud', 'saibar apradh', 'electronic transactions', 'data theft', 'cyberstalking'],
    ),
    LegalDocument(
      id: 'crim_004',
      titleEn: 'Narcotic Drug Offenses',
      titleNp: 'लागूऔषध सम्बन्धी अपराध',
      category: 'Criminal Law',
      contentEn: 'The Narcotic Drugs Control Act of Nepal regulates the production, sale, distribution, possession, and use of narcotic drugs and psychotropic substances. The act categorizes controlled substances into different schedules based on their potential for abuse and medical utility. It is illegal to produce, manufacture, possess, sell, purchase, transport, or import any narcotic drug without a license from the relevant authority. The cultivation of opium poppy, cannabis, and coca plants is strictly prohibited. The punishment for drug offenses depends on the type and quantity of the substance involved. Possession of small quantities may result in imprisonment of up to five years and fines, while trafficking in large quantities may lead to life imprisonment. Repeat offenders face enhanced penalties. The act also provides for the rehabilitation and treatment of drug addicts. The Narcotics Control Bureau and the Nepal Police are responsible for enforcement. Special courts have been established to expedite trials of drug-related cases.',
      contentNp: 'नेपालको लागूऔषध नियन्त्रण ऐनले लागूऔषध र मनोविकार उत्पन्न गर्ने पदार्थहरूको उत्पादन, बिक्री, वितरण, कब्जा र प्रयोगलाई नियमन गर्दछ। ऐनले दुरुपयोगको सम्भावना र चिकित्सकीय उपयोगिताको आधारमा नियन्त्रित पदार्थहरूलाई विभिन्न अनुसूचीमा वर्गीकृत गर्दछ। सम्बन्धित निकायबाट इजाजतपत्रविना कुनै पनि लागूऔषध उत्पादन, निर्माण, कब्जा, बिक्री, खरिद, ढुवानी वा आयात गर्नु गैरकानूनी छ। अफिम, गाँजा र कोका बिरुवाको खेती पूर्ण रूपमा निषेधित छ। लागूऔषध अपराधको सजाय पदार्थको प्रकार र परिमाणमा निर्भर गर्दछ। सानो परिमाणको कब्जाले पाँच वर्षसम्म कैद र जरिवाना हुन सक्छ, जबकि ठूलो परिमाणको तस्करीले जन्मकैद हुन सक्छ। पुनरावृत्ति अपराधीहरूले कडा सजाय भोग्नुपर्दछ। ऐनले लागूऔषध दुर्व्यसनीहरूको पुनर्स्थापना र उपचारको पनि व्यवस्था गरेको छ। लागूऔषध नियन्त्रण ब्युरो र नेपाल प्रहरी कार्यान्वयनको लागि जिम्मेवार छन्। लागूऔषध सम्बन्धी मुद्दाहरूको छिटो सुनुवाइको लागि विशेष अदालतहरू स्थापना गरिएको छ।',
      keywords: ['narcotics', 'drug trafficking', 'cannabis', 'opium', 'lagu aushadh', 'drug abuse', 'rehabilitation', 'narcotic control'],
    ),
    LegalDocument(
      id: 'crim_005',
      titleEn: 'Criminal Procedure and Bail',
      titleNp: 'फौजदारी कार्यविधि र धरौटी',
      category: 'Criminal Law',
      contentEn: 'The criminal procedure in Nepal is governed by the Criminal Procedure Code, which establishes the process for investigation, arrest, bail, trial, and appeal. A person may be arrested upon a warrant issued by a court or without a warrant in case of flagrant offenses. The arrested person must be produced before the nearest judicial authority within twenty-four hours of arrest. Bail may be granted by the court or the investigating officer depending on the nature and gravity of the offense. For bailable offenses, bail is a matter of right. For non-bailable offenses, bail is at the discretion of the court, considering factors such as the likelihood of the accused fleeing, tampering with evidence, or committing further offenses. The trial process involves the filing of a charge sheet, the examination of witnesses, the presentation of evidence, and the final arguments. The accused has the right to legal representation and the right to remain silent. Appeals against conviction may be filed in the High Court and the Supreme Court.',
      contentNp: 'नेपालको फौजदारी कार्यविधि फौजदारी कार्यविधि संहिताद्वारा नियमन गरिन्छ, जसले अनुसन्धान, गिरफ्तारी, धरौटी, मुद्दा सुनुवाइ र पुनरावेदनको प्रक्रिया स्थापित गर्दछ। व्यक्तिलाई अदालतले जारी गरेको वारण्टबमोजिम वा रङ्गेहात अपराधको अवस्थामा वारण्टविना पनि गिरफ्तार गर्न सकिन्छ। गिरफ्तार व्यक्तिलाई चौबीस घण्टाभित्र नजिकको न्यायिक अधिकारीसमक्ष पेश गर्नुपर्दछ। धरौटी अपराधको प्रकृति र गम्भीरताको आधारमा अदालत वा अनुसन्धान अधिकारीले प्रदान गर्न सक्छ। धरौटीमा छोड्न मिल्ने अपराधको लागि, धरौटी पाउने अधिकार हुन्छ। धरौटीमा नछोड्ने अपराधको लागि, धरौटी अदालतको विवेकमा निर्भर हुन्छ, जसमा अभियुक्तको फरार हुने, प्रमाण नष्ट गर्ने वा थप अपराध गर्ने सम्भावनालाई विचार गरिन्छ। मुद्दा सुनुवाइ प्रक्रियामा अभियोगपत्र दायर, साक्षीहरूको जाँच, प्रमाण पेश र अन्तिम बहस समावेश हुन्छ। अभियुक्तलाई कानूनी प्रतिनिधित्वको अधिकार र मौन रहने अधिकार हुन्छ। दोषी ठहरिएको विरुद्ध पुनरावेदन उच्च अदालत र सर्वोच्च अदालतमा दायर गर्न सकिन्छ।',
      keywords: ['criminal procedure', 'arrest', 'bail', 'trial', 'dharauti', 'charge sheet', 'appeal', 'legal representation'],
    ),
    LegalDocument(
      id: 'crim_006',
      titleEn: 'Domestic Violence Offenses',
      titleNp: 'घरेलु हिंसा सम्बन्धी अपराध',
      category: 'Criminal Law',
      contentEn: 'The Domestic Violence (Offense and Punishment) Act of Nepal defines domestic violence as any form of physical, mental, sexual, or economic harm inflicted on a family member. Physical violence includes hitting, pushing, beating, or any act causing bodily harm. Mental and emotional violence includes intimidation, harassment, verbal abuse, and threats. Sexual violence within marriage or domestic relationships is also recognized as an offense. Economic violence includes deprivation of financial resources, denial of property rights, and restrictions on employment. The victim may file a complaint at the local police station, the Women Cell, or directly in court. The court may issue a protection order requiring the perpetrator to cease the violent behavior and stay away from the victim. Interim relief may include shelter, medical assistance, and financial support. The offender may be punished with imprisonment of up to six months and a fine. Counseling and rehabilitation programs may be ordered. The act emphasizes the protection of women and children, who are most vulnerable to domestic violence.',
      contentNp: 'नेपालको घरेलु हिंसा (अपराध र सजाय) ऐनले घरेलु हिंसालाई परिवारको सदस्यलाई हुने कुनै पनि प्रकारको शारीरिक, मानसिक, यौन वा आर्थिक हानिको रूपमा परिभाषित गर्दछ। शारीरिक हिंसामा हिर्काउने, धकेल्ने, कुटपिट गर्ने वा शारीरिक हानि पुर्याउने कुनै पनि कार्य समावेश हुन्छ। मानसिक र भावनात्मक हिंसामा धम्की, उत्पीडन, मौखिक दुर्व्यवहार र डरत्रास समावेश हुन्छ। वैवाहिक वा घरेलु सम्बन्धभित्रको यौन हिंसालाई पनि अपराधको रूपमा मान्यता दिइएको छ। आर्थिक हिंसामा आर्थिक स्रोतबाट वञ्चित गर्ने, सम्पत्तिको अधिकारबाट इन्कार गर्ने र रोजगारीमा प्रतिबन्ध लगाउने समावेश हुन्छ। पीडितले स्थानीय प्रहरी चौकी, महिला सेल वा प्रत्यक्ष अदालतमा उजुरी दिन सक्छ। अदालतले हिंसक व्यवहार बन्द गर्न र पीडितबाट टाढा रहन संरक्षण आदेश जारी गर्न सक्छ। अन्तरिम राहतमा आश्रय, चिकित्सा सहायता र आर्थिक सहयोग समावेश हुन सक्छ। अपराधीलाई छ महिनासम्म कैद र जरिवानाको सजाय हुन सक्छ। परामर्श र पुनर्स्थापना कार्यक्रमहरूको आदेश दिन सकिन्छ। ऐनले घरेलु हिंसाको लागि सबैभन्दा संवेदनशील महिला र बालबालिकाको संरक्षणलाई जोड दिन्छ।',
      keywords: ['domestic violence', 'protection order', 'shelter', 'gharelu hinsa', 'women safety', 'counseling', 'interim relief', 'physical abuse'],
    ),
    LegalDocument(
      id: 'crim_007',
      titleEn: 'Corruption and Bribery Offenses',
      titleNp: 'भ्रष्टाचार र घूस सम्बन्धी अपराध',
      category: 'Criminal Law',
      contentEn: 'The Prevention of Corruption Act of Nepal criminalizes corrupt practices including bribery, embezzlement, abuse of position, and illicit enrichment. Bribery involves the offering, giving, soliciting, or accepting of any undue advantage to influence the actions of a public official. Embezzlement involves the misappropriation of public funds or property by a person entrusted with such funds or property. Abuse of position occurs when a public official uses their official position to obtain an undue advantage for themselves or others. Illicit enrichment is defined as the significant increase in a public official assets that cannot be reasonably explained by their legitimate income. The Commission for the Investigation of Abuse of Authority (CIAA) is the primary anti-corruption agency with the power to investigate and prosecute corruption cases. The Special Court hears corruption cases. Conviction may result in imprisonment of up to ten years and a fine equal to the amount involved. Public officials are required to submit annual statements of their assets and liabilities.',
      contentNp: 'नेपालको भ्रष्टाचार निवारण ऐनले घूस, गबन, पदको दुरुपयोग र गैरकानूनी सम्पत्ति आर्जन लगायत भ्रष्टाचारजन्य गतिविधिहरूलाई आपराधिक ठहराउँदछ। घूसमा कुनै सार्वजनिक अधिकारीको कार्यलाई प्रभावित पार्न कुनै पनि अनुचित लाभ प्रस्ताव गर्ने, दिने, माग गर्ने वा स्वीकार गर्ने कार्य समावेश हुन्छ। गबनमा कसैलाई सुम्पिएको सार्वजनिक कोष वा सम्पत्तिको दुरुपयोग समावेश हुन्छ। पदको दुरुपयोग तब हुन्छ जब सार्वजनिक अधिकारीले आफ्नो वा अरूको लागि अनुचित लाभ प्राप्त गर्न आफ्नो आधिकारिक पद प्रयोग गर्दछ। गैरकानूनी सम्पत्ति आर्जनलाई सार्वजनिक अधिकारीको सम्पत्तिमा भएको उल्लेखनीय वृद्धि जुन उसको वैध आयद्वारा उचित रूपमा व्याख्या गर्न नसकिने गरी परिभाषित गरिएको छ। अख्तियार दुरुपयोग अनुसन्धान आयोग प्रमुख भ्रष्टाचारविरोधी निकाय हो जसलाई भ्रष्टाचारका मुद्दाहरूको अनुसन्धान र अभियोजन गर्ने अधिकार छ। विशेष अदालतले भ्रष्टाचारको मुद्दा सुन्ने गर्दछ। दोषी ठहर भएमा दश वर्षसम्म कैद र संलग्न रकम बराबर जरिवाना हुन सक्छ। सार्वजनिक अधिकारीहरूले वार्षिक रूपमा आफ्नो सम्पत्ति र दायित्वको विवरण पेश गर्नुपर्दछ।',
      keywords: ['corruption', 'bribery', 'embezzlement', 'CIAA', 'bhrashtachar', 'ghus', 'illicit enrichment', 'special court'],
    ),

    // ===== LOCAL GOVERNANCE (5) =====
    LegalDocument(
      id: 'local_001',
      titleEn: 'Municipal Powers and Functions',
      titleNp: 'नगरपालिकाको अधिकार र कार्यहरू',
      category: 'Local Governance',
      contentEn: 'Municipalities in Nepal exercise executive, legislative, and financial powers as provided by the Constitution and the Local Government Operation Act. Each municipality has a Municipal Council composed of the mayor, deputy mayor, ward chairs, and ward members elected from each ward. The Municipal Council has the power to make laws, regulations, and bylaws on matters within its jurisdiction, including local infrastructure, sanitation, education, health, and cultural activities. The municipality is responsible for the preparation and implementation of annual development plans and budgets. It has the power to levy taxes, fees, and service charges within its territory, including property tax, vehicle tax, business tax, and entertainment tax. The municipality must also manage public utilities such as water supply, street lighting, waste management, and local roads. Decisions of the Municipal Council are executed by the municipal executive office headed by the chief administrative officer.',
      contentNp: 'नेपालका नगरपालिकाहरूले संविधान र स्थानीय सरकार सञ्चालन ऐनले प्रदत्त गरेबमोजिम कार्यकारी, विधायिकी र वित्तीय अधिकार प्रयोग गर्दछन्। प्रत्येक नगरपालिकामा प्रत्येक वडाबाट निर्वाचित मेयर, उपमेयर, वडाध्यक्ष र वडा सदस्यहरू मिलेको नगरसभा हुन्छ। नगरसभालाई स्थानीय पूर्वाधार, सरसफाइ, शिक्षा, स्वास्थ्य र सांस्कृतिक गतिविधिसहित आफ्नो अधिकारक्षेत्रभित्रका विषयहरूमा कानून, नियम र उपनियम बनाउने अधिकार हुन्छ। नगरपालिका वार्षिक विकास योजना र बजेटको तर्जुमा र कार्यान्वयनको लागि जिम्मेवार हुन्छ। यसलाई आफ्नो क्षेत्रभित्र सम्पत्ति कर, सवारी कर, व्यवसाय कर र मनोरञ्जन कर सहित कर, शुल्क र सेवा शुल्क लगाउने अधिकार हुन्छ। नगरपालिकाले खानेपानी, सडक बत्ती, फोहरमैला व्यवस्थापन र स्थानीय सडक जस्ता सार्वजनिक उपयोगिताहरूको पनि व्यवस्थापन गर्नुपर्दछ। नगरसभाका निर्णयहरू प्रमुख प्रशासकीय अधिकृतको नेतृत्वमा रहेको नगर कार्यपालिकाको कार्यालयद्वारा कार्यान्वयन गरिन्छ।',
      keywords: ['municipality', 'mayor', 'municipal council', 'property tax', 'nagarpalika', 'local government', 'development plan', 'ward'],
    ),
    LegalDocument(
      id: 'local_002',
      titleEn: 'Ward Committee Functions',
      titleNp: 'वडा समितिको कार्यहरू',
      category: 'Local Governance',
      contentEn: 'Each ward in a municipality or rural municipality has a Ward Committee consisting of the Ward Chair and four Ward Members elected from the ward. The Ward Committee is the basic unit of local governance and plays a vital role in grassroots democracy. The functions of the Ward Committee include identifying local development needs, preparing ward-level plans, monitoring development projects, recommending subsidy recipients, maintaining vital registration records such as births and deaths, and resolving local disputes through mediation. The Ward Chair presides over Ward Committee meetings and represents the ward in the Municipal or Rural Municipal Council. The Ward Committee also assists in the collection of local taxes and fees, maintains public assets within the ward, and coordinates with the municipal office for service delivery. Ward Committees are required to conduct regular public hearings to ensure transparency and citizen participation in local governance.',
      contentNp: 'नगरपालिका वा गाउँपालिकाको प्रत्येक वडामा वडाध्यक्ष र वडाबाट निर्वाचित चार वडा सदस्यहरू मिलेको वडा समिति हुन्छ। वडा समिति स्थानीय शासनको आधारभूत एकाइ हो र तल्लो तहको लोकतन्त्रमा महत्त्वपूर्ण भूमिका खेल्दछ। वडा समितिको कार्यहरूमा स्थानीय विकास आवश्यकताहरू पहिचान गर्ने, वडा-स्तरीय योजनाहरू तयार गर्ने, विकास परियोजनाहरूको अनुगमन गर्ने, अनुदान प्राप्तकर्ताहरू सिफारिस गर्ने, जन्म र मृत्यु जस्ता महत्त्वपूर्ण दर्ता अभिलेखहरू राख्ने, र मध्यस्थतामार्फत स्थानीय विवादहरू समाधान गर्ने समावेश छन्। वडाध्यक्षले वडा समितिको बैठकको अध्यक्षता गर्दछ र नगरसभा वा गाउँसभामा वडाको प्रतिनिधित्व गर्दछ। वडा समितिले स्थानीय कर र शुल्क सङ्कलनमा पनि सहयोग गर्दछ, वडाभित्रका सार्वजनिक सम्पत्तिहरूको व्यवस्थापन गर्दछ, र सेवा प्रवाहको लागि नगरपालिका कार्यालयसँग समन्वय गर्दछ। वडा समितिहरूले पारदर्शिता र स्थानीय शासनमा नागरिक सहभागिता सुनिश्चित गर्न नियमित सार्वजनिक सुनुवाइ सञ्चालन गर्नुपर्दछ।',
      keywords: ['ward committee', 'ward chair', 'public hearing', 'vital registration', 'wada samiti', 'grassroots', 'mediation', 'local development'],
    ),
    LegalDocument(
      id: 'local_003',
      titleEn: 'Rural Municipality Administration',
      titleNp: 'गाउँपालिका प्रशासन',
      category: 'Local Governance',
      contentEn: 'Rural municipalities (Gaunpalikas) are the local governance units in rural areas of Nepal, each composed of several wards. The Rural Municipal Council is the legislative body, consisting of the Chair, Vice-Chair, Ward Chairs, and Ward Members. The Chair and Vice-Chair are elected directly by the voters of the rural municipality. The Rural Municipal Council has the authority to formulate policies, laws, and regulations for the development of the rural municipality. Key responsibilities include agricultural development, local infrastructure, basic health services, primary education, local road construction and maintenance, water supply, and sanitation. Rural municipalities have financial powers to collect taxes, fees, and revenues from natural resources within their territory. They also serve as the primary coordinator for service delivery from federal and provincial governments to the local level. The administrative head of a rural municipality is the Chief Administrative Officer.',
      contentNp: 'गाउँपालिकाहरू नेपालको ग्रामीण क्षेत्रमा स्थानीय शासनको एकाइ हुन्, जसमध्ये प्रत्येकमा धेरै वडाहरू हुन्छन्। गाउँ सभा विधायिकी निकाय हो, जसमा अध्यक्ष, उपाध्यक्ष, वडाध्यक्ष र वडा सदस्यहरू हुन्छन्। अध्यक्ष र उपाध्यक्ष गाउँपालिकाका मतदाताद्वारा प्रत्यक्ष निर्वाचित हुन्छन्। गाउँ सभालाई गाउँपालिकाको विकासको लागि नीति, कानून र नियमहरू बनाउने अधिकार हुन्छ। मुख्य जिम्मेवारीहरूमा कृषि विकास, स्थानीय पूर्वाधार, आधारभूत स्वास्थ्य सेवा, प्राथमिक शिक्षा, स्थानीय सडक निर्माण र मर्मत, खानेपानी र सरसफाइ समावेश छन्। गाउँपालिकाहरूलाई आफ्नो क्षेत्रभित्र कर, शुल्क र प्राकृतिक स्रोतबाट राजस्व सङ्कलन गर्ने वित्तीय अधिकार हुन्छ। तिनीहरू संघीय र प्रदेश सरकारहरूबाट स्थानीय तहमा सेवा प्रवाहको लागि प्रमुख समन्वयकर्ताको रूपमा पनि काम गर्दछन्। गाउँपालिकाको प्रशासनिक प्रमुख प्रमुख प्रशासकीय अधिकृत हुन्।',
      keywords: ['rural municipality', 'gaunpalika', 'chair', 'rural council', 'gaun sava', 'agriculture', 'local roads', 'natural resource tax'],
    ),
    LegalDocument(
      id: 'local_004',
      titleEn: 'Local Tax and Revenue Collection',
      titleNp: 'स्थानीय कर र राजस्व सङ्कलन',
      category: 'Local Governance',
      contentEn: 'Local governments in Nepal have the constitutional right to impose taxes and collect revenue on matters specified in the Local Government List. The principal sources of local revenue include property tax, house and land tax, business tax, vehicle tax, entertainment tax, advertisement tax, and service fees for permits and licenses. Property tax is levied on the value of immovable property within the local jurisdiction and is a major source of revenue for municipalities. Business tax is charged on businesses operating within the locality based on their turnover or nature. Local governments may also collect fees for services such as garbage collection, building permits, and road usage. Revenue collection is governed by the Local Government Operation Act and the respective municipal or rural municipal acts. Tax rates are set by the Local Council and must be published in the local gazette. Exemptions may be granted for religious, charitable, and cultural institutions. Taxpayers have the right to appeal against tax assessments.',
      contentNp: 'नेपालका स्थानीय सरकारहरूलाई स्थानीय सरकारको सूचीमा उल्लेखित विषयहरूमा कर लगाउने र राजस्व सङ्कलन गर्ने संवैधानिक अधिकार छ। स्थानीय राजस्वका प्रमुख स्रोतहरूमा सम्पत्ति कर, घरजग्गा कर, व्यवसाय कर, सवारी कर, मनोरञ्जन कर, विज्ञापन कर, र स्वीकृति र इजाजतपत्रको सेवा शुल्क समावेश छन्। सम्पत्ति कर स्थानीय क्षेत्राधिकारभित्रको स्थावर सम्पत्तिको मूल्यमा लगाइन्छ र नगरपालिकाको लागि राजस्वको प्रमुख स्रोत हो। व्यवसाय कर स्थानीय क्षेत्रभित्र सञ्चालित व्यवसायहरूमा उनीहरूको कारोबार वा प्रकृतिको आधारमा लगाइन्छ। स्थानीय सरकारहरूले फोहर सङ्कलन, भवन अनुमति र सडक प्रयोग जस्ता सेवाहरूको लागि पनि शुल्क सङ्कलन गर्न सक्दछन्। राजस्व सङ्कलन स्थानीय सरकार सञ्चालन ऐन र सम्बन्धित नगरपालिका वा गाउँपालिका ऐनद्वारा नियमन गरिन्छ। कर दरहरू स्थानीय सभाले निर्धारण गर्दछ र स्थानीय राजपत्रमा प्रकाशित गर्नुपर्दछ। धार्मिक, परोपकारी र सांस्कृतिक संस्थाहरूको लागि छुट दिन सकिन्छ। करदाताहरूलाई कर मूल्याङ्कनविरुद्ध पुनरावेदन गर्ने अधिकार हुन्छ।',
      keywords: ['tax', 'revenue', 'property tax', 'business tax', 'local tax', 'sthaniya kar', 'tax exemption', 'appeal'],
    ),
    LegalDocument(
      id: 'local_005',
      titleEn: 'Provincial-Local Coordination',
      titleNp: 'प्रदेश-स्थानीय समन्वय',
      category: 'Local Governance',
      contentEn: 'The Constitution of Nepal establishes a system of coordination between provincial and local governments through the Provincial-Local Coordination Council. Each province has a Coordination Council chaired by the Chief Minister, including provincial ministers and representatives of local governments. The Council facilitates the harmonization of policies and plans between the provincial and local levels, resolves disputes regarding the exercise of powers, and ensures the efficient delivery of services. Provincial governments provide financial equalization grants to local governments to reduce disparities in fiscal capacity. Local governments must submit their annual plans and budgets to the provincial government for coordination. The province may monitor and evaluate local-level projects funded by the provincial government. Disputes between local governments are adjudicated by the relevant High Court. The coordination mechanism ensures that federal, provincial, and local levels work in harmony for balanced regional development.',
      contentNp: 'नेपालको संविधानले प्रदेश-स्थानीय समन्वय परिषद्मार्फत प्रदेश र स्थानीय सरकारबीच समन्वयको प्रणाली स्थापित गरेको छ। प्रत्येक प्रदेशमा मुख्यमन्त्रीको अध्यक्षतामा समन्वय परिषद् हुन्छ, जसमा प्रदेश मन्त्रीहरू र स्थानीय सरकारका प्रतिनिधिहरू हुन्छन्। परिषद्ले प्रदेश र स्थानीय तहबीच नीति र योजनाहरूको सामञ्जस्यता सहजीकरण गर्दछ, अधिकार प्रयोग सम्बन्धी विवादहरू समाधान गर्दछ र सेवाहरूको प्रभावकारी प्रवाह सुनिश्चित गर्दछ। प्रदेश सरकारहरूले वित्तीय क्षमतामा रहेको असमानता कम गर्न स्थानीय सरकारहरूलाई वित्तीय समानीकरण अनुदान प्रदान गर्दछन्। स्थानीय सरकारहरूले समन्वयको लागि आफ्नो वार्षिक योजना र बजेट प्रदेश सरकारमा पेश गर्नुपर्दछ। प्रदेशले प्रदेश सरकारद्वारा कोषित स्थानीय-स्तरीय परियोजनाहरूको अनुगमन र मूल्याङ्कन गर्न सक्छ। स्थानीय सरकारहरूबीचको विवाद सम्बन्धित उच्च अदालतले निरुपण गर्दछ। समन्वय संयन्त्रले सन्तुलित क्षेत्रीय विकासको लागि संघीय, प्रदेश र स्थानीय तहहरू सामञ्जस्यपूर्ण रूपमा काम गर्ने सुनिश्चित गर्दछ।',
      keywords: ['coordination', 'provincial-local', 'equalization grant', 'samanyan parishad', 'provincial plan', 'dispute resolution', 'budget coordination', 'regional development'],
    ),

    // ===== PROPERTY LAW (5) =====
    LegalDocument(
      id: 'prop_001',
      titleEn: 'Land Registration and Title',
      titleNp: 'जग्गा दर्ता र लिखत पास',
      category: 'Property Law',
      contentEn: 'Land registration in Nepal is governed by the Land Revenue Act and the Land Registration Act. All immovable property must be registered with the Land Revenue Office (Malpot Office) in the district where the property is located. The registration process involves verifying the title of the transferor, surveying the property, paying applicable taxes and fees, and recording the transaction in the official land register. A registered title deed (lal purja) serves as conclusive evidence of ownership. Transfers of land through sale, gift, inheritance, or mortgage must be registered to be legally valid. The Land Revenue Office maintains a complete record of land ownership, boundaries, and encumbrances. Any person acquiring land must apply for registration within thirty days of the transaction. Unregistered transactions do not confer valid title. The government also maintains a land use classification system that categorizes land as agricultural, residential, commercial, industrial, or public use.',
      contentNp: 'नेपालमा जग्गा दर्ता भूमिसम्बन्धी राजस्व ऐन र जग्गा दर्ता ऐनद्वारा नियमन गरिन्छ। सबै स्थावर सम्पत्ति सम्पत्ति अवस्थित जिल्लाको मालपोत कार्यालयमा दर्ता गरिनुपर्दछ। दर्ता प्रक्रियामा हस्तान्तरणकर्ताको लिखत परीक्षण, सम्पत्तिको नापी, लागू हुने कर र शुल्क भुक्तानी, र आधिकारिक जग्गा अभिलेखमा कारोबार रेकर्ड गर्ने कार्य समावेश हुन्छ। दर्ता भएको लालपूर्जा स्वामित्वको अन्तिम प्रमाणको रूपमा काम गर्दछ। बिक्री, उपहार, उत्तराधिकार वा धितोमार्फत जग्गाको हस्तान्तरण कानूनी रूपमा वैध हुनको लागि दर्ता गरिनुपर्दछ। मालपोत कार्यालयले जग्गाको स्वामित्व, सीमाना र भारहरूको पूर्ण अभिलेख राख्दछ। जग्गा प्राप्त गर्ने कुनै पनि व्यक्तिले कारोबारको तीस दिनभित्र दर्ताको लागि आवेदन दिनुपर्दछ। दर्ता नगरिएका कारोबारहरूले वैध स्वामित्व प्रदान गर्दैन। सरकारले जग्गालाई कृषि, आवासीय, व्यावसायिक, औद्योगिक वा सार्वजनिक प्रयोगको रूपमा वर्गीकरण गर्ने भू-उपयोग वर्गीकरण प्रणाली पनि सञ्चालन गर्दछ।',
      keywords: ['land registration', 'lal purja', 'title deed', 'malpot', 'jagga darta', 'land revenue', 'property transfer', 'land use classification'],
    ),
    LegalDocument(
      id: 'prop_002',
      titleEn: 'Land Acquisition and Compensation',
      titleNp: 'जग्गा प्राप्ति र क्षतिपूर्ति',
      category: 'Property Law',
      contentEn: 'The Land Acquisition Act of Nepal empowers the government to acquire private land for public purposes, including infrastructure development, urban planning, and public facilities. Before acquiring land, the government must issue a public notice, conduct a survey of the land, determine the compensation amount, and provide affected persons an opportunity to file objections. Compensation is determined based on the market value of the land at the time of acquisition, plus an additional amount for compulsory acquisition. Compensation includes the value of the land, structures on the land, standing crops, trees, and any other improvements. The government must also provide rehabilitation assistance to displaced persons, including alternative housing or land where feasible. The land owner has the right to challenge the acquisition or the compensation amount in court. The Land Revenue Office facilitates the acquisition process and disburses compensation. Special provisions exist for the acquisition of land belonging to marginalized communities and indigenous peoples.',
      contentNp: 'नेपालको जग्गा प्राप्ति ऐनले सरकारलाई पूर्वाधार विकास, सहरी योजना र सार्वजनिक सुविधा सहित सार्वजनिक उद्देश्यका लागि निजी जग्गा प्राप्त गर्ने अधिकार दिन्छ। जग्गा प्राप्त गर्नुअघि, सरकारले सार्वजनिक सूचना जारी गर्नुपर्दछ, जग्गाको सर्भे गर्नुपर्दछ, क्षतिपूर्ति रकम निर्धारण गर्नुपर्दछ र प्रभावित व्यक्तिहरूलाई आपत्ति दर्ता गर्ने अवसर प्रदान गर्नुपर्दछ। क्षतिपूर्ति प्राप्तिको समयमा जग्गाको बजार मूल्यमा आधारित हुन्छ, साथै अनिवार्य प्राप्तिको लागि अतिरिक्त रकम पनि समावेश हुन्छ। क्षतिपूर्तिमा जग्गाको मूल्य, जग्गामा रहेका संरचनाहरू, उभिएका बाली, रूखहरू र अन्य कुनै पनि सुधारहरू समावेश हुन्छन्। सरकारले विस्थापित व्यक्तिहरूलाई सम्भव भएसम्म वैकल्पिक आवास वा जग्गा सहित पुनर्स्थापना सहायता पनि प्रदान गर्नुपर्दछ। जग्गाधनीले अदालतमा प्राप्ति वा क्षतिपूर्ति रकमविरुद्ध चुनौती दिने अधिकार हुन्छ। मालपोत कार्यालयले प्राप्ति प्रक्रिया सहजीकरण गर्दछ र क्षतिपूर्ति वितरण गर्दछ। सीमान्तकृत समुदाय र आदिवासी जनजातिको जग्गा प्राप्तिको लागि विशेष व्यवस्थाहरू छन्।',
      keywords: ['land acquisition', 'compensation', 'public purpose', 'jagga prapti', 'kshatipurti', 'rehabilitation', 'market value', 'displaced persons'],
    ),
    LegalDocument(
      id: 'prop_003',
      titleEn: 'Mortgage and Lien on Property',
      titleNp: 'सम्पत्तिमा धितो र धारणाधिकार',
      category: 'Property Law',
      contentEn: 'A mortgage is the transfer of an interest in immovable property as security for the repayment of a debt or performance of an obligation. In Nepal, mortgages are governed by the Muluki Ain and the specific mortgage laws. The person who mortgages the property is the mortgagor, and the person receiving the mortgage is the mortgagee. A registered mortgage deed must be executed and registered at the Land Revenue Office. The mortgage may be possessory, where the mortgagee takes possession of the property, or non-possessory, where the mortgagor retains possession. Foreclosure allows the mortgagee to take ownership of the property if the mortgagor defaults. Redemption is the right of the mortgagor to recover the property by paying the debt after the due date. A lien is a right to retain possession of another property until a debt is satisfied. Equitable mortgages are recognized where title deeds are deposited as security without formal registration. Priority among competing mortgages is determined by the date of registration.',
      contentNp: 'धितो भनेको ऋणको भुक्तानी वा दायित्वको पालनाको लागि सुरक्षाको रूपमा स्थावर सम्पत्तिमा हित हस्तान्तरण गर्नु हो। नेपालमा, धितो मुलुकी ऐन र विशेष धितो कानूनहरूद्वारा नियमन गरिन्छ। जसले सम्पत्ति धितो राख्छ उसलाई धितो राख्ने भनिन्छ, र धितो प्राप्त गर्नेलाई धितो राख्न पाउने भनिन्छ। दर्ता गरिएको धितोको लिखत मालपोत कार्यालयमा कार्यान्वयन र दर्ता गरिनुपर्दछ। धितो कब्जायुक्त हुन सक्छ, जहाँ धितो राख्न पाउनेले सम्पत्तिको कब्जा लिन्छ, वा गैर-कब्जायुक्त, जहाँ धितो राख्नेले कब्जा राख्छ। धितो राख्न पाउनेले धितो राख्नेले भुक्तानी नगरेमा सम्पत्तिको स्वामित्व लिन सक्छ। फिरौती भनेको धितो राख्नेले म्यादपछि ऋण तिरेर सम्पत्ति फिर्ता पाउने अधिकार हो। धारणाधिकार भनेको ऋण सन्तुष्ट नभएसम्म अर्काको सम्पत्तिको कब्जा राख्ने अधिकार हो। औपचारिक दर्ता विना लिखत जम्मा गरी सुरक्षाको रूपमा राख्दा समतामूलक धितो मान्यता दिइन्छ। प्रतिस्पर्धी धितोहरूबीच प्राथमिकता दर्ताको मितिद्वारा निर्धारण गरिन्छ।',
      keywords: ['mortgage', 'lien', 'foreclosure', 'redemption', 'dhito', 'dharandhikar', 'possessory mortgage', 'equitable mortgage'],
    ),
    LegalDocument(
      id: 'prop_004',
      titleEn: 'Land Revenue and Taxation',
      titleNp: 'भूमि राजस्व र कराधान',
      category: 'Property Law',
      contentEn: 'Land revenue in Nepal is collected by the Land Revenue Office based on the type, classification, and use of land. Agricultural land is assessed for revenue based on its productivity classification (abbal, doyam, sim, chahar). Residential and commercial land is assessed based on the prevailing market value determined by the government. Land tax must be paid annually by the landowner to the local government. Failure to pay land tax may result in penalty interest and eventual auction of the property. The land revenue system also includes registration fees and stamp duties payable on transfers of land. The rate of registration fee is a percentage of the property value as assessed by the government. Capital gains tax is applicable on the sale of land held for investment. The government periodically revises land valuation rates for tax purposes. Exemptions from land tax are available for agricultural land used by small farmers, land owned by religious and charitable institutions, and public land used for government purposes.',
      contentNp: 'नेपालमा भूमि राजस्व मालपोत कार्यालयद्वारा भूमिको प्रकार, वर्गीकरण र प्रयोगको आधारमा सङ्कलन गरिन्छ। कृषि जग्गालाई यसको उत्पादन क्षमता वर्गीकरण (अब्बल, दोयम, सिम, चहार) को आधारमा राजस्व निर्धारण गरिन्छ। आवासीय र व्यावसायिक जग्गाको मूल्याङ्कन सरकारले निर्धारण गरेको प्रचलित बजार मूल्यको आधारमा गरिन्छ। जग्गा कर जग्गाधनीले स्थानीय सरकारलाई वार्षिक रूपमा तिर्नुपर्दछ। जग्गा कर तिर्न बेवास्ता गरेमा जरिवाना ब्याज र अन्ततः सम्पत्ति लिलामी हुन सक्छ। भूमि राजस्व प्रणालीमा जग्गा हस्तान्तरणमा तिर्नुपर्ने दर्ता शुल्क र स्टाम्प शुल्क पनि समावेश हुन्छ। दर्ता शुल्कको दर सरकारले मूल्याङ्कन गरेको सम्पत्ति मूल्यको प्रतिशत हो। लगानीको लागि राखिएको जग्गाको बिक्रीमा पुँजीगत लाभ कर लागू हुन्छ। सरकारले कर उद्देश्यका लागि जग्गा मूल्याङ्कन दरहरू आवधिक रूपमा परिमार्जन गर्दछ। साना किसानले प्रयोग गरेको कृषि जग्गा, धार्मिक र परोपकारी संस्थाको जग्गा र सरकारी उद्देश्यका लागि प्रयोग गरिएको सार्वजनिक जग्गाको लागि जग्गा करमा छुट उपलब्ध छ।',
      keywords: ['land revenue', 'malpot', 'stamp duty', 'capital gains tax', 'bhumi rajaswa', 'land tax', 'registration fee', 'tax exemption'],
    ),
    LegalDocument(
      id: 'prop_005',
      titleEn: 'Rental and Leasehold Property Rights',
      titleNp: 'भाडा र लीजहोल्ड सम्पत्ति अधिकार',
      category: 'Property Law',
      contentEn: 'Leasehold property rights in Nepal allow a person to use and occupy land or buildings owned by another person for a specified period in exchange for rent. A lease agreement must specify the parties, the property description, the lease term, the rent amount and payment schedule, and the rights and obligations of each party. Lease terms for residential properties are typically for one to five years, while commercial leases may extend up to thirty years. Government-owned land may be leased on a long-term basis for industrial, commercial, or agricultural purposes. The lessee has the right to peaceful enjoyment of the property but must not make structural changes without the lessor consent. The lessor has the right to inspect the property and to re-enter if rent is not paid. Upon expiration of the lease, the lessee must vacate the property unless the lease is renewed. Renewal rights may be negotiated in the original lease agreement. Improvements made by the lessee become the property of the lessor unless otherwise agreed.',
      contentNp: 'नेपालमा लीजहोल्ड सम्पत्ति अधिकारले व्यक्तिलाई अर्को व्यक्तिको स्वामित्वमा रहेको जग्गा वा भवन एक निर्दिष्ट अवधिको लागि भाडाको बदलामा प्रयोग र कब्जा गर्न अनुमति दिन्छ। भाडा सम्झौताले पक्षहरू, सम्पत्तिको विवरण, भाडा अवधि, भाडा रकम र भुक्तानी तालिका, र प्रत्येक पक्षको अधिकार र दायित्वहरू उल्लेख गर्नुपर्दछ। आवासीय सम्पत्तिको लागि भाडा अवधि सामान्यतया एक देखि पाँच वर्षको हुन्छ, जबकि व्यावसायिक भाडा तीस वर्षसम्म विस्तार हुन सक्छ। सरकारी स्वामित्वको जग्गा औद्योगिक, व्यावसायिक वा कृषि उद्देश्यका लागि दीर्घकालीन रूपमा भाडामा दिन सकिन्छ। भाडावाललाई सम्पत्तिको शान्तिपूर्ण उपभोग गर्ने अधिकार हुन्छ तर भाडादाताको सहमतिविना संरचनात्मक परिवर्तन गर्न हुँदैन। भाडादातालाई सम्पत्ति निरीक्षण गर्ने र भाडा नतिरेमा पुनः प्रवेश गर्ने अधिकार हुन्छ। भाडा अवधि समाप्त भएपछि भाडावालाले सम्पत्ति खाली गर्नुपर्दछ जबसम्म भाडा नवीकरण गरिएको हुँदैन। नवीकरण अधिकार मूल भाडा सम्झौतामा वार्ता गर्न सकिन्छ। भाडावालले गरेको सुधार अन्यथा सहमति नभएसम्म भाडादाताको सम्पत्ति हुन्छ।',
      keywords: ['leasehold', 'rental', 'lease agreement', 'lessee', 'lessor', 'bhadawal', 'renewal', 'vacate'],
    ),

    // ===== CORPORATE LAW (7) =====
    LegalDocument(
      id: 'corp_001',
      titleEn: 'Company Registration and Incorporation',
      titleNp: 'कम्पनी दर्ता र निगमीकरण',
      category: 'Corporate Law',
      contentEn: 'The Companies Act of Nepal governs the registration, incorporation, and regulation of companies. A company may be registered as a private company, public company, or non-profit company. A private company must have at least one member and cannot exceed 100 members, and its shares are not traded publicly. A public company must have at least seven members and may offer shares to the public. The incorporation process involves reserving the company name, preparing the memorandum of association and articles of association, filing the required documents with the Office of the Company Registrar, and obtaining a certificate of incorporation. The memorandum of association contains the company name, registered office, objectives, and share capital. The articles of association set out the internal management rules. A company acquires legal personality upon incorporation, enabling it to own property, enter contracts, and sue or be sued in its own name. Foreign companies may establish branch offices or subsidiary companies in Nepal with approval.',
      contentNp: 'नेपालको कम्पनी ऐनले कम्पनीको दर्ता, निगमीकरण र नियमन गर्दछ। कम्पनी निजी कम्पनी, सार्वजनिक कम्पनी वा नाफा नकमाउने कम्पनीको रूपमा दर्ता गर्न सकिन्छ। निजी कम्पनीमा कम्तीमा एक सदस्य हुनुपर्दछ र १०० सदस्यभन्दा बढी हुन सक्दैन, र यसको शेयर सार्वजनिक रूपमा कारोबार हुँदैन। सार्वजनिक कम्पनीमा कम्तीमा सात सदस्य हुनुपर्दछ र यसले सर्वसाधारणलाई शेयर प्रस्ताव गर्न सक्छ। निगमीकरण प्रक्रियामा कम्पनीको नाम आरक्षित गर्ने, संस्थापन नियमावली र नियमावली तयार गर्ने, कम्पनी रजिष्ट्रारको कार्यालयमा आवश्यक कागजात दायर गर्ने र निगमीकरणको प्रमाणपत्र प्राप्त गर्ने समावेश छ। संस्थापन नियमावलीमा कम्पनीको नाम, दर्ता कार्यालय, उद्देश्य र शेयर पुँजी उल्लेख हुन्छ। नियमावलीले आन्तरिक व्यवस्थापन नियमहरू निर्धारण गर्दछ। कम्पनी निगमीकरणपछि कानूनी व्यक्तित्व प्राप्त गर्दछ, जसले गर्दा यो आफ्नो नाममा सम्पत्ति राख्न, सम्झौता गर्न र मुद्दा हाल्न वा हालिन सक्छ। विदेशी कम्पनीहरूले अनुमोदनपछि नेपालमा शाखा कार्यालय वा सहायक कम्पनी स्थापना गर्न सक्छन्।',
      keywords: ['company registration', 'incorporation', 'private company', 'public company', 'campani darta', 'memorandum of association', 'share capital', 'legal personality'],
    ),
    LegalDocument(
      id: 'corp_002',
      titleEn: 'Banking and Financial Institution Regulation',
      titleNp: 'बैंक तथा वित्तीय संस्था नियमन',
      category: 'Corporate Law',
      contentEn: 'The banking sector in Nepal is regulated by the Nepal Rastra Bank Act and the Banks and Financial Institutions Act. Nepal Rastra Bank, the central bank, is responsible for monetary policy, regulation, and supervision of banks and financial institutions. Banks are categorized as commercial banks, development banks, finance companies, and microfinance institutions. Each category has specific capital requirements, lending limits, and operational restrictions. Banks must maintain a minimum capital adequacy ratio, cash reserve ratio, and statutory liquidity ratio as prescribed by the central bank. Banks are required to conduct know-your-customer due diligence and maintain proper records to prevent money laundering and terrorist financing. The Deposit Insurance and Credit Guarantee Corporation provides deposit insurance up to a specified amount per depositor. The central bank conducts regular inspections and may impose penalties for non-compliance, including fines, suspension of licenses, or liquidation in extreme cases.',
      contentNp: 'नेपालको बैंकिङ क्षेत्र नेपाल राष्ट्र बैंक ऐन र बैंक तथा वित्तीय संस्था ऐनद्वारा नियमन गरिन्छ। केन्द्रीय बैंक, नेपाल राष्ट्र बैंक, मौद्रिक नीति, नियमन र बैंक तथा वित्तीय संस्थाको सुपरीवेक्षणको लागि जिम्मेवार छ। बैंकहरूलाई वाणिज्य बैंक, विकास बैंक, वित्त कम्पनी र लघुवित्त संस्थाको रूपमा वर्गीकृत गरिन्छ। प्रत्येक श्रेणीमा विशिष्ट पुँजी आवश्यकता, ऋण सीमा र सञ्चालनगत प्रतिबन्धहरू हुन्छन्। बैंकहरूले केन्द्रीय बैंकले तोकेबमोजिम न्यूनतम पुँजी पर्याप्तता अनुपात, नगद मौज्दात अनुपात र वैधानिक तरलता अनुपात कायम राख्नुपर्दछ। बैंकहरूले ग्राहक चिनारी गर्ने उपयुक्त परीक्षण सञ्चालन गर्नुपर्दछ र मनी लान्ड्रिङ र आतंकवादी वित्तपोषण रोक्न उचित अभिलेख राख्नुपर्दछ। निक्षेप बीमा तथा ऋण सुरक्षण निगमले प्रति निक्षेपकर्ता एक निर्दिष्ट रकमसम्म निक्षेप बीमा प्रदान गर्दछ। केन्द्रीय बैंकले नियमित निरीक्षण गर्दछ र गैर-अनुपालनको लागि जरिवाना, इजाजतपत्र निलम्बन वा चरम अवस्थामा परिसमापन सहित दण्ड लगाउन सक्छ।',
      keywords: ['banking', 'nepal rastra bank', 'capital adequacy', 'interest rate', 'banking regulation', 'deposit insurance', 'commercial bank', 'microfinance'],
    ),
    LegalDocument(
      id: 'corp_003',
      titleEn: 'Labor Relations and Employment Law',
      titleNp: 'श्रम सम्बन्ध र रोजगार कानून',
      category: 'Corporate Law',
      contentEn: 'The Labor Act of Nepal governs employment relationships, working conditions, and workers rights. The act applies to all enterprises with ten or more workers and establishes minimum standards for wages, working hours, leave, and occupational safety. The minimum wage is set by the government and reviewed periodically. The standard working week is forty-eight hours with at least one rest day. Workers are entitled to annual leave, sick leave, maternity leave of fourteen weeks with full pay, and public holidays. The act requires employers to provide a safe working environment, personal protective equipment, and health insurance. Employers cannot discriminate on the basis of gender, caste, religion, or disability. The act prohibits child labor and forced labor. A worker may be terminated only for just cause with notice or compensation in lieu of notice. Trade unions have the right to organize and bargain collectively. Disputes between employers and workers are resolved through negotiation, mediation, or adjudication by the Labor Court.',
      contentNp: 'नेपालको श्रम ऐनले रोजगार सम्बन्ध, काम गर्ने अवस्था र कामदारको अधिकारलाई नियमन गर्दछ। ऐन दश वा दशभन्दा बढी कामदार भएका सबै उद्यमहरूमा लागू हुन्छ र ज्याला, काम गर्ने समय, बिदा र व्यावसायिक सुरक्षाको लागि न्यूनतम मापदण्ड स्थापित गर्दछ। न्यूनतम ज्याला सरकारले निर्धारण गर्दछ र आवधिक रूपमा पुनरावलोकन गर्दछ। मानक कार्य सप्ताह अडतालीस घण्टा हो र कम्तीमा एक दिन आराम हुनुपर्दछ। कामदारहरू वार्षिक बिदा, सिक बिदा, पूर्ण तलबसहित चौध हप्ताको सुत्केरी बिदा र सार्वजनिक बिदाहरूको हकदार हुन्छन्। ऐनले रोजगारदातालाई सुरक्षित कामको वातावरण, व्यक्तिगत सुरक्षा उपकरण र स्वास्थ्य बीमा उपलब्ध गराउन आवश्यक छ। रोजगारदाताले लिङ्ग, जात, धर्म वा अपाङ्गताको आधारमा भेदभाव गर्न सक्दैन। ऐनले बाल श्रम र जबरजस्ती श्रमलाई निषेध गर्दछ। कामदारलाई सूचना वा सूचनाको बदलामा क्षतिपूर्तिसहित उचित कारणले मात्र बर्खास्त गर्न सकिन्छ। ट्रेड युनियनहरूलाई संगठित हुने र सामूहिक सौदाबाजी गर्ने अधिकार हुन्छ। रोजगारदाता र कामदारबीचको विवाद वार्ता, मध्यस्थता वा श्रम अदालतद्वारा निरुपण गरिन्छ।',
      keywords: ['labor law', 'minimum wage', 'maternity leave', 'trade union', 'shram ain', 'working hours', 'child labor', 'social security'],
    ),
    LegalDocument(
      id: 'corp_004',
      titleEn: 'Income Tax and Corporate Taxation',
      titleNp: 'आयकर र कर्पोरेट कराधान',
      category: 'Corporate Law',
      contentEn: 'The Income Tax Act of Nepal governs the taxation of individuals and entities. Companies are subject to corporate income tax on their worldwide income at rates specified in the annual Finance Act. The standard corporate tax rate is twenty-five percent, with reduced rates for certain sectors such as hydropower, tourism, and information technology. Small and medium enterprises are subject to a lower rate. Capital gains tax is applicable on the sale of shares and assets. Value Added Tax at thirteen percent is levied on the supply of goods and services. Advance tax payments are required quarterly based on estimated income. Tax returns must be filed annually by the due date, and failure to file may result in penalties and interest. The Inland Revenue Department administers tax collection and conducts audits. Taxpayers have the right to appeal tax assessments to the Revenue Tribunal. Double taxation avoidance agreements exist with several countries to prevent the same income from being taxed twice.',
      contentNp: 'नेपालको आयकर ऐनले व्यक्ति र संस्थाहरूको कराधानलाई नियमन गर्दछ। कम्पनीहरू वार्षिक वित्त ऐनमा तोकिएको दरमा आफ्नो विश्वव्यापी आयमा कर्पोरेट आयकरको अधीनमा हुन्छन्। मानक कर्पोरेट कर दर पच्चीस प्रतिशत हो, जसमा जलविद्युत, पर्यटन र सूचना प्रविधि जस्ता निश्चित क्षेत्रहरूको लागि घटाइएको दर छ। साना र मझौला उद्यमहरू कम दरको अधीनमा छन्। शेयर र सम्पत्ति बिक्रीमा पुँजीगत लाभ कर लागू हुन्छ। वस्तु र सेवाको आपूर्तिमा तेह्र प्रतिशत मूल्य अभिवृद्धि कर लगाइन्छ। अनुमानित आयको आधारमा त्रैमासिक रूपमा अग्रिम कर भुक्तानी आवश्यक हुन्छ। कर रिटर्न वार्षिक रूपमा निर्धारित मितिसम्म दायर गर्नुपर्दछ, र दायर नगरेमा जरिवाना र ब्याज लाग्न सक्छ। आन्तरिक राजस्व विभागले कर सङ्कलन प्रशासन गर्दछ र लेखापरीक्षण सञ्चालन गर्दछ। करदाताहरूलाई राजस्व न्यायाधिकरणमा कर मूल्याङ्कनविरुद्ध पुनरावेदन गर्ने अधिकार हुन्छ। धेरै देशहरूसँग दोहोरो कर उन्मूलन सम्झौताहरू छन् जसले एउटै आयमा दुई पटक कर लाग्नबाट रोक्छ।',
      keywords: ['income tax', 'corporate tax', 'VAT', 'capital gains tax', 'ayakar', 'korporate kar', 'tax return', 'transfer pricing'],
    ),
    LegalDocument(
      id: 'corp_005',
      titleEn: 'Intellectual Property and Trademark Law',
      titleNp: 'बौद्धिक सम्पत्ति र ट्रेडमार्क कानून',
      category: 'Corporate Law',
      contentEn: 'Intellectual property in Nepal is protected under the Patent, Design, and Trademark Act and the Copyright Act. A trademark is a distinctive sign, symbol, word, or phrase that identifies and distinguishes the goods or services of one enterprise from others. Trademarks must be registered with the Department of Industry to receive legal protection. Registration is valid for seven years and may be renewed. A patent protects new inventions and is granted for a period of seven years from the filing date of the application. Industrial designs are protected for five years with the possibility of renewal. Copyright protection extends to literary, musical, artistic works, and computer software. Copyright is automatically granted upon creation and lasts for fifty years after the author death for most works. Infringement of intellectual property rights may result in injunctions, damages, and criminal penalties. Nepal is a signatory to several international intellectual property treaties, including the TRIPS Agreement.',
      contentNp: 'नेपालमा बौद्धिक सम्पत्ति पेटेन्ट, डिजाइन र ट्रेडमार्क ऐन र प्रतिलिपि अधिकार ऐन अन्तर्गत संरक्षित छ। ट्रेडमार्क एक विशिष्ट चिह्न, प्रतीक, शब्द वा वाक्यांश हो जसले एक उद्यमको वस्तु वा सेवालाई अरूभन्दा छुट्याउँदछ। ट्रेडमार्कहरू कानूनी संरक्षण प्राप्त गर्न उद्योग विभागमा दर्ता गरिनुपर्दछ। दर्ता सात वर्षको लागि वैध हुन्छ र नवीकरण गर्न सकिन्छ। पेटेन्टले नयाँ आविष्कारहरूको संरक्षण गर्दछ र आवेदन दायर मितिदेखि सात वर्षको अवधिको लागि प्रदान गरिन्छ। औद्योगिक डिजाइनहरू नवीकरणको सम्भावनासहित पाँच वर्षको लागि संरक्षित हुन्छन्। प्रतिलिपि अधिकार संरक्षण साहित्यिक, साङ्गीतिक, कलात्मक कार्यहरू र कम्प्युटर सफ्टवेरसम्म विस्तारित छ। प्रतिलिपि अधिकार सिर्जनापछि स्वचालित रूपमा प्रदान हुन्छ र अधिकांश कार्यहरूको लागि लेखकको मृत्युपछि पचास वर्षसम्म रहन्छ। बौद्धिक सम्पत्ति अधिकारको उल्लङ्घनले आदेश, क्षतिपूर्ति र आपराधिक दण्डको परिणाम हुन सक्छ। नेपाल TRIPS सम्झौता सहित धेरै अन्तर्राष्ट्रिय बौद्धिक सम्पत्ति सन्धिहरूको पक्ष राष्ट्र हो।',
      keywords: ['trademark', 'patent', 'copyright', 'intellectual property', 'trademark darta', 'copyright', 'industrial design', 'TRIPS'],
    ),
    LegalDocument(
      id: 'corp_006',
      titleEn: 'Insurance and Risk Management',
      titleNp: 'बीमा र जोखिम व्यवस्थापन',
      category: 'Corporate Law',
      contentEn: 'The Insurance Act of Nepal regulates the insurance industry, including the establishment, operation, and supervision of insurance companies. Insurance is classified into life insurance and non-life insurance (general insurance). Life insurance includes endowment plans, term insurance, whole life policies, and annuity plans. General insurance covers fire, marine, motor, health, aviation, engineering, and miscellaneous insurance. The Nepal Insurance Authority is the regulatory body responsible for licensing, monitoring, and supervising insurance companies. Every insurance company must maintain minimum paid-up capital, solvency margins, and reinsurance arrangements as specified by the authority. Insurance contracts must be based on the principle of utmost good faith, requiring both parties to disclose all material facts. The policyholder must have an insurable interest in the subject matter of the insurance. Claims must be paid within thirty days of receipt of all required documents. Disputes between insurers and policyholders are resolved through the Insurance Committee or the courts.',
      contentNp: 'नेपालको बीमा ऐनले बीमा कम्पनीहरूको स्थापना, सञ्चालन र सुपरीवेक्षण सहित बीमा उद्योगलाई नियमन गर्दछ। बीमालाई जीवन बीमा र गैर-जीवन बीमा (साधारण बीमा) मा वर्गीकृत गरिन्छ। जीवन बीमामा अन्त्येष्टि योजना, म्यादी बीमा, सम्पूर्ण जीवन नीति र वार्षिकी योजनाहरू समावेश छन्। साधारण बीमाले आगो, सामुद्रिक, मोटर, स्वास्थ्य, उड्डयन, इन्जिनियरिङ र विविध बीमा समावेश गर्दछ। नेपाल बीमा प्राधिकरण नियामक निकाय हो जुन बीमा कम्पनीहरूको इजाजतपत्र, अनुगमन र सुपरीवेक्षणको लागि जिम्मेवार छ। प्रत्येक बीमा कम्पनीले प्राधिकरणले तोकेबमोजिम न्यूनतम चुक्ता पुँजी, समाधान मार्जिन र पुनर्बीमा व्यवस्था कायम राख्नुपर्दछ। बीमा सम्झौता पूर्ण विश्वासको सिद्धान्तमा आधारित हुनुपर्दछ, जसले दुवै पक्षलाई सबै भौतिक तथ्यहरू खुलासा गर्न आवश्यक गर्दछ। नीतिधारकसँग बीमाको विषय वस्तुमा बीमायोग्य हित हुनुपर्दछ। सबै आवश्यक कागजात प्राप्त भएको तीस दिनभित्र दाबी भुक्तानी गर्नुपर्दछ। बीमक र नीतिधारकबीचको विवाद बीमा समिति वा अदालतमार्फत समाधान गरिन्छ।',
      keywords: ['insurance', 'life insurance', 'general insurance', 'bima', 'nepal insurance authority', 'claim', 'solvency', 'premium'],
    ),
    LegalDocument(
      id: 'corp_007',
      titleEn: 'Insolvency and Bankruptcy Law',
      titleNp: 'दिवालियापन र दिवाला कानून',
      category: 'Corporate Law',
      contentEn: 'The Insolvency Act of Nepal provides a legal framework for the insolvency and bankruptcy of companies and individuals. The act aims to facilitate the rehabilitation of financially distressed companies and ensure fair treatment of creditors. A company may be declared insolvent if it is unable to pay its debts as they fall due or if its liabilities exceed its assets. Insolvency proceedings may be initiated by the company itself, its creditors, or the regulatory authority. Upon declaration of insolvency, a liquidation committee is appointed to manage the affairs of the company, realize its assets, and distribute the proceeds among creditors. Secured creditors have priority over unsecured creditors in the distribution of assets. The act also provides for a reorganization process, where a company may propose a restructuring plan to continue its operations while repaying its debts over an extended period. Individual bankruptcy provisions apply to persons unable to pay their debts.',
      contentNp: 'नेपालको दिवालियापन ऐनले कम्पनी र व्यक्तिहरूको दिवाला र दिवालियापनको लागि कानूनी ढाँचा प्रदान गर्दछ। ऐनको उद्देश्य आर्थिक रूपमा समस्याग्रस्त कम्पनीहरूको पुनर्स्थापनाको सुविधा प्रदान गर्नु र लेनदारहरूको निष्पक्ष व्यवहार सुनिश्चित गर्नु हो। कम्पनीलाई दिवाला घोषित गर्न सकिन्छ यदि यसले ऋण परिपक्व हुँदा तिनीहरूको भुक्तानी गर्न असमर्थ छ वा यसको दायित्व सम्पत्तिभन्दा बढी छ। दिवाला कारबाही कम्पनी आफैंले, यसका लेनदारहरूले वा नियामक निकायले सुरु गर्न सक्छ। दिवाला घोषणापछि, कम्पनीको मामिला व्यवस्थापन गर्न, सम्पत्ति वसुली गर्न र लेनदारहरूबीच आम्दानी वितरण गर्न परिसमापन समिति नियुक्त गरिन्छ। सुरक्षित लेनदारहरूलाई सम्पत्ति वितरणमा असुरक्षित लेनदारहरूभन्दा प्राथमिकता हुन्छ। ऐनले पुनर्संरचना प्रक्रिया पनि प्रदान गर्दछ, जहाँ कम्पनीले विस्तारित अवधिमा ऋण चुक्ता गर्दै आफ्नो सञ्चालन जारी राख्न पुनर्संरचना योजना प्रस्ताव गर्न सक्छ। व्यक्तिगत दिवालियापन व्यवस्था ऋण तिर्न असमर्थ व्यक्तिहरूमा लागू हुन्छ।',
      keywords: ['insolvency', 'bankruptcy', 'liquidation', 'reorganization', 'diwala', 'lakshan', 'secured creditor', 'restructuring'],
    ),

    // ===== PUBLIC ADMINISTRATION (5) =====
    LegalDocument(
      id: 'admin_001',
      titleEn: 'Civil Service Rules and Regulations',
      titleNp: 'निजामती सेवा नियम र विनियम',
      category: 'Public Administration',
      contentEn: 'The Civil Service Act of Nepal governs the recruitment, appointment, promotion, transfer, and discipline of civil servants. The civil service is organized into various services and groups, including administrative, technical, auditing, legal, and foreign affairs. Recruitment is conducted through open competitive examinations administered by the Public Service Commission. The Commission ensures merit-based selection through written examinations, interviews, and group discussions. Civil servants have defined career progression paths based on seniority and performance evaluations. Transfers are made in the public interest, with provisions for tenure in a position. Disciplinary actions for misconduct may include warnings, fines, suspension, demotion, or dismissal. The Civil Service Tribunal hears appeals from civil servants against disciplinary actions. The act also establishes codes of conduct requiring civil servants to be politically neutral, impartial, and dedicated to public service.',
      contentNp: 'नेपालको निजामती सेवा ऐनले निजामती कर्मचारीको भर्ना, नियुक्ति, बढुवा, सरुवा र अनुशासनलाई नियमन गर्दछ। निजामती सेवा प्रशासनिक, प्राविधिक, लेखापरीक्षण, कानूनी र परराष्ट्र मामिला सहित विभिन्न सेवा र समूहमा संगठित गरिएको छ। भर्ना लोक सेवा आयोगद्वारा सञ्चालित खुला प्रतिस्पर्धात्मक परीक्षामार्फत गरिन्छ। आयोगले लिखित परीक्षा, अन्तर्वार्ता र समूह छलफलमार्फत योग्यतामा आधारित छनौट सुनिश्चित गर्दछ। निजामती कर्मचारीहरूको ज्येष्ठता र कार्यसम्पादन मूल्याङ्कनको आधारमा निर्धारित क्यारियर प्रगति पथ हुन्छ। सरुवा सार्वजनिक हितमा गरिन्छ, जसमा एक पदमा रहने अवधिको व्यवस्था हुन्छ। कदाचारको लागि अनुशासनात्मक कारबाहीमा चेतावनी, जरिवाना, निलम्बन, पद घटुवा वा बर्खास्त समावेश हुन सक्छ। निजामती सेवा न्यायाधिकरणले निजामती कर्मचारीहरूको अनुशासनात्मक कारबाहीविरुद्धको पुनरावेदन सुन्दछ। ऐनले निजामती कर्मचारीहरूलाई राजनीतिक रूपमा तटस्थ, निष्पक्ष र सार्वजनिक सेवाप्रति समर्पित हुन आचारसंहिता पनि स्थापित गर्दछ।',
      keywords: ['civil service', 'public service commission', 'recruitment', 'promotion', 'nijamati sewa', 'lok sewa ayog', 'discipline', 'code of conduct'],
    ),
    LegalDocument(
      id: 'admin_002',
      titleEn: 'Public Procurement Regulations',
      titleNp: 'सार्वजनिक खरिद नियमावली',
      category: 'Public Administration',
      contentEn: 'The Public Procurement Act of Nepal governs the procurement of goods, services, and works by public entities. The act establishes principles of transparency, competition, fairness, and value for money in public procurement. All procurements above specified thresholds must be conducted through open competitive bidding. The bidding process includes publication of invitation for bids, submission of bids, bid evaluation, and award of contract. The evaluation criteria must be objective and disclosed in advance. A bid security and performance guarantee are required. Contracts must be awarded to the lowest evaluated bidder who meets the qualifying criteria. The act also provides for alternative procurement methods such as limited bidding, single source procurement, and emergency procurement under specific circumstances. Public entities must prepare annual procurement plans and publish procurement information on the public procurement portal. The Public Procurement Monitoring Office oversees compliance and may impose penalties for violations.',
      contentNp: 'नेपालको सार्वजनिक खरिद ऐनले सार्वजनिक निकायहरूद्वारा वस्तु, सेवा र कामको खरिदलाई नियमन गर्दछ। ऐनले सार्वजनिक खरिदमा पारदर्शिता, प्रतिस्पर्धा, निष्पक्षता र मूल्यको लागि मूल्यको सिद्धान्तहरू स्थापित गर्दछ। निर्दिष्ट सीमाभन्दा माथिको सबै खरिद खुला प्रतिस्पर्धात्मक बोलपत्रमार्फत गरिनुपर्दछ। बोलपत्र प्रक्रियामा बोलपत्र आह्वानको प्रकाशन, बोलपत्र पेश, बोलपत्र मूल्याङ्कन र सम्झौता प्रदान समावेश हुन्छ। मूल्याङ्कन मापदण्ड वस्तुनिष्ठ र पूर्व प्रकाशित हुनुपर्दछ। बोलपत्र सुरक्षा र कार्यसम्पादन जमानत आवश्यक हुन्छ। सम्झौता योग्यता मापदण्ड पूरा गर्ने न्यूनतम मूल्याङ्कन गरिएको बोलपत्रदातालाई प्रदान गरिनुपर्दछ। ऐनले सीमित बोलपत्र, एकल स्रोत खरिद र आपतकालीन खरिद जस्ता वैकल्पिक खरिद विधिहरू पनि विशिष्ट परिस्थितिहरूमा प्रदान गर्दछ। सार्वजनिक निकायहरूले वार्षिक खरिद योजना तयार गर्नुपर्दछ र सार्वजनिक खरिद पोर्टलमा खरिद जानकारी प्रकाशित गर्नुपर्दछ। सार्वजनिक खरिद अनुगमन कार्यालयले अनुपालनको सुपरीवेक्षण गर्दछ र उल्लङ्घनको लागि दण्ड लगाउन सक्छ।',
      keywords: ['public procurement', 'bidding', 'tender', 'competitive bidding', 'sarbajanik kharid', 'bid evaluation', 'government contract', 'procurement monitoring'],
    ),
    LegalDocument(
      id: 'admin_003',
      titleEn: 'Immigration and Passport Regulations',
      titleNp: 'अध्यागमन र राहदानी नियमावली',
      category: 'Public Administration',
      contentEn: 'The Immigration Act of Nepal regulates the entry, stay, and departure of foreign nationals in Nepal. All foreign nationals entering Nepal must possess a valid passport and obtain the appropriate visa from Nepali diplomatic missions abroad or at ports of entry. Visa categories include tourist, business, student, work, residential, and diplomatic visas. Visas may be extended by the Department of Immigration upon application. Foreign nationals must register with the immigration authorities if staying beyond certain periods. The act provides for the establishment of immigration checkpoints at all international airports and border crossings. Overstaying a visa is a punishable offense resulting in fines and possible deportation. The Passport Act governs the issuance of passports to Nepali citizens. There are three types of passports: ordinary, official, and diplomatic. Passports are valid for ten years and may be renewed. Lost or damaged passports must be reported to the nearest Nepali diplomatic mission or the Department of Passports.',
      contentNp: 'नेपालको अध्यागमन ऐनले नेपालमा विदेशी नागरिकको प्रवेश, बसाइ र प्रस्थानलाई नियमन गर्दछ। नेपाल प्रवेश गर्ने सबै विदेशी नागरिकसँग वैध राहदानी र नेपाली कूटनीतिक नियोग वा प्रवेश बिन्दुमा उपयुक्त भिसा प्राप्त गरेको हुनुपर्दछ। भिसा कोटिहरूमा पर्यटक, व्यवसाय, विद्यार्थी, कार्य, आवासीय र कूटनीतिक भिसा समावेश छन्। भिसा अध्यागमन विभागले आवेदनमा विस्तार गर्न सक्छ। विदेशी नागरिकहरूले निश्चित अवधिभन्दा बढी बसेमा अध्यागमन अधिकारीहरूमा दर्ता गराउनुपर्दछ। ऐनले सबै अन्तर्राष्ट्रिय विमानस्थल र सीमा नाकाहरूमा अध्यागमन जाँच चौकी स्थापनाको व्यवस्था गरेको छ। भिसा अवधि नाघेर बस्नु दण्डनीय अपराध हो जसको परिणाम जरिवाना र सम्भावित निर्वासन हुन सक्छ। राहदानी ऐनले नेपाली नागरिकलाई राहदानी जारी गर्ने नियमन गर्दछ। राहदानीका तीन प्रकार छन्: साधारण, आधिकारिक र कूटनीतिक। राहदानी दस वर्षको लागि वैध हुन्छ र नवीकरण गर्न सकिन्छ। हराएको वा बिग्रेको राहदानी नजिकको नेपाली कूटनीतिक नियोग वा राहदानी विभागमा जानकारी दिनुपर्दछ।',
      keywords: ['immigration', 'passport', 'visa', 'foreign nationals', 'adhyagaman', 'rahadani', 'deportation', 'border control'],
    ),
    LegalDocument(
      id: 'admin_004',
      titleEn: 'Citizenship Certificate Issuance',
      titleNp: 'नागरिकता प्रमाणपत्र जारी',
      category: 'Public Administration',
      contentEn: 'The Citizenship Certificate Issuance Act governs the procedures for obtaining citizenship certificates in Nepal. Applications for citizenship by descent must be submitted to the District Administration Office of the applicant district of origin with required documents including proof of parents citizenship, birth certificate, and residence proof. Citizenship by birth applies to persons born in Nepal before specified dates. Naturalized citizenship may be granted to foreign nationals who have resided in Nepal for at least fifteen years, can speak Nepali, and have renounced their previous citizenship. Citizenship certificates are issued by the District Administration Office and must bear the photograph and signature of the holder. A citizenship certificate is essential for obtaining a passport, voter registration, land registration, government employment, and other legal purposes. The government maintains a central database of all citizenship records. The Home Ministry oversees citizenship matters and may revoke citizenship obtained through fraud or misrepresentation.',
      contentNp: 'नागरिकता प्रमाणपत्र जारी ऐनले नेपालमा नागरिकता प्रमाणपत्र प्राप्त गर्ने प्रक्रियाहरू नियमन गर्दछ। वंशजको आधारमा नागरिकताको लागि आवेदन आवेदकको मूल जिल्लाको जिल्ला प्रशासन कार्यालयमा आमाबाबुको नागरिकताको प्रमाण, जन्म दर्ता र बसोबासको प्रमाण सहित आवश्यक कागजात पेश गर्नुपर्दछ। जन्मको आधारमा नागरिकता निर्दिष्ट मितिअघि नेपालमा जन्मिएका व्यक्तिहरूमा लागू हुन्छ। प्राकृतिकीकृत नागरिकता कम्तीमा पन्ध्र वर्ष नेपालमा बसेको, नेपाली बोल्न सक्ने र आफ्नो अघिल्लो नागरिकता त्याग गरेका विदेशी नागरिकहरूलाई प्रदान गर्न सकिन्छ। नागरिकता प्रमाणपत्र जिल्ला प्रशासन कार्यालयले जारी गर्दछ र यसमा धारकको फोटो र हस्ताक्षर हुनुपर्दछ। नागरिकता प्रमाणपत्र राहदानी, मतदाता दर्ता, जग्गा दर्ता, सरकारी रोजगारी र अन्य कानूनी उद्देश्यहरूको लागि आवश्यक हुन्छ। सरकारले सबै नागरिकता अभिलेखको केन्द्रीय डाटाबेस राख्दछ। गृह मन्त्रालयले नागरिकता मामिलाहरूको सुपरीवेक्षण गर्दछ र धोखाधडी वा गलत बयानबाट प्राप्त नागरिकता खारेज गर्न सक्छ।',
      keywords: ['citizenship certificate', 'naturalization', 'district administration', 'nagarikata pramanpatra', 'home ministry', 'voter registration', 'fraud', 'central database'],
    ),
    LegalDocument(
      id: 'admin_005',
      titleEn: 'Administrative Tribunals and Justice',
      titleNp: 'प्रशासनिक न्यायाधिकरण र न्याय',
      category: 'Public Administration',
      contentEn: 'Administrative tribunals in Nepal adjudicate disputes between citizens and government agencies. The primary administrative tribunals include the Civil Service Tribunal, the Revenue Tribunal, the Labor Court, and the Debt Recovery Tribunal. These tribunals provide specialized and expeditious resolution of disputes in their respective areas. The procedure before administrative tribunals is less formal than regular courts. Parties may present their cases in person or through legal representatives. Tribunals have the power to summon witnesses, require production of documents, and make binding decisions. Decisions of tribunals may be appealed to the High Court or Supreme Court on questions of law. The Government Cases Act governs the conduct of litigation by government agencies. The Attorney General office represents the government in legal proceedings. The principle of natural justice must be followed, including the right to be heard and the rule against bias.',
      contentNp: 'नेपालमा प्रशासनिक न्यायाधिकरणहरूले नागरिक र सरकारी निकायहरूबीचको विवादहरूको निरुपण गर्दछन्। प्रमुख प्रशासनिक न्यायाधिकरणहरूमा निजामती सेवा न्यायाधिकरण, राजस्व न्यायाधिकरण, श्रम अदालत र ऋण असुली न्यायाधिकरण समावेश छन्। यी न्यायाधिकरणहरूले आ-आफ्नो क्षेत्रमा विशिष्ट र छिटो विवाद समाधान प्रदान गर्दछन्। प्रशासनिक न्यायाधिकरणमा कार्यविधि सामान्य अदालतको तुलनामा कम औपचारिक हुन्छ। पक्षहरूले आफ्नो मुद्दा व्यक्तिगत रूपमा वा कानूनी प्रतिनिधिमार्फत पेश गर्न सक्छन्। न्यायाधिकरणहरूलाई साक्षी बोलाउने, कागजात पेश गर्न आवश्यक गर्ने र बाध्यकारी निर्णय गर्ने अधिकार हुन्छ। न्यायाधिकरणको निर्णयविरुद्ध कानूनको प्रश्नमा उच्च अदालत वा सर्वोच्च अदालतमा पुनरावेदन गर्न सकिन्छ। सरकारी मुद्दा ऐनले सरकारी निकायहरूद्वारा मुद्दा सञ्चालनलाई नियमन गर्दछ। महान्यायाधिवक्ताको कार्यालयले कानूनी कारबाहीमा सरकारको प्रतिनिधित्व गर्दछ। सुनुवाइ पाउने अधिकार र पूर्वाग्रहविरुद्धको नियम सहित प्राकृतिक न्यायको सिद्धान्त पालना गरिनुपर्दछ।',
      keywords: ['administrative tribunal', 'civil service tribunal', 'revenue tribunal', 'labor court', 'prashasanik nyayadhikaran', 'natural justice', 'appeal', 'attorney general'],
    ),

    // ===== HUMAN RIGHTS (5) =====
    LegalDocument(
      id: 'hr_001',
      titleEn: 'Child Rights and Protection',
      titleNp: 'बाल अधिकार र संरक्षण',
      category: 'Human Rights',
      contentEn: 'The Children Act of Nepal guarantees the fundamental rights of every child, including the right to survival, development, protection, and participation. Every child has the right to a name and nationality, to live with their parents, to education, to health care, to rest and leisure, and to be protected from all forms of abuse, neglect, exploitation, and discrimination. The act prohibits child marriage, child labor, and corporal punishment. The minimum age for employment is fourteen years, and hazardous work is prohibited for all minors. Special provisions exist for children in conflict with the law, including juvenile justice procedures, separate detention facilities, and rehabilitation programs. The National Child Rights Council monitors the implementation of child rights and addresses violations. Children have the right to express their views in matters affecting them, and their views shall be given due weight. Any person who causes harm to a child may be subject to criminal liability.',
      contentNp: 'नेपालको बालबालिका सम्बन्धी ऐनले प्रत्येक बालबालिकाको मौलिक अधिकारको ग्यारेन्टी गर्दछ, जसमा बाँच्ने, विकास, संरक्षण र सहभागिताको हक समावेश छ। प्रत्येक बालबालिकालाई नाम र राष्ट्रियता, आमाबाबुसँग बस्ने, शिक्षा, स्वास्थ्य सेवा, आराम र मनोरञ्जन, र सबै प्रकारको दुर्व्यवहार, उपेक्षा, शोषण र भेदभावबाट संरक्षित हुने अधिकार छ। ऐनले बाल विवाह, बाल श्रम र शारीरिक दण्डलाई निषेध गर्दछ। रोजगारको लागि न्यूनतम उमेर चौध वर्ष हो, र सबै नाबालिगहरूको लागि जोखिमपूर्ण काम निषेधित छ। कानूनसँग द्वन्द्वमा रहेका बालबालिकाको लागि विशेष व्यवस्थाहरू छन्, जसमा किशोर न्याय प्रक्रिया, पृथक हिरासत सुविधा र पुनर्स्थापना कार्यक्रमहरू समावेश छन्। राष्ट्रिय बाल अधिकार परिषद्ले बाल अधिकारको कार्यान्वयनको अनुगमन गर्दछ र उल्लङ्घनहरूलाई सम्बोधन गर्दछ। बालबालिकालाई उनीहरूलाई असर गर्ने मामिलाहरूमा आफ्नो विचार व्यक्त गर्ने अधिकार छ, र तिनीहरूको विचारलाई उचित महत्त्व दिइनेछ। बालबालिकालाई हानि पुर्याउने कुनै पनि व्यक्ति आपराधिक दायित्वको अधीनमा हुन सक्छ।',
      keywords: ['child rights', 'child protection', 'child labor', 'juvenile justice', 'bal adhikar', 'child marriage', 'national child rights council', 'rehabilitation'],
    ),
    LegalDocument(
      id: 'hr_002',
      titleEn: 'Human Trafficking Prevention',
      titleNp: 'मानव बेचबिखन निवारण',
      category: 'Human Rights',
      contentEn: 'The Human Trafficking and Transportation (Control) Act of Nepal criminalizes all forms of human trafficking, including trafficking for sexual exploitation, forced labor, organ removal, and domestic servitude. The act defines trafficking as the recruitment, transportation, transfer, harboring, or receipt of persons through coercion, force, fraud, deception, or abuse of power for the purpose of exploitation. The consent of the victim is irrelevant where any of these means have been used. Special provisions protect women and children as they are the most vulnerable to trafficking. The National Human Rights Commission and the Ministry of Women, Children and Senior Citizens coordinate anti-trafficking efforts. Punishment for trafficking ranges from ten to twenty years imprisonment and fines of up to five hundred thousand rupees. Victims of trafficking are entitled to protection, shelter, medical care, counseling, legal aid, and compensation. The act also criminalizes the promotion of sex tourism and the publication of advertisements for trafficking.',
      contentNp: 'नेपालको मानव बेचबिखन तथा ओसारपसार (नियन्त्रण) ऐनले यौन शोषण, जबरजस्ती श्रम, अङ्ग हटाउने र घरेलु दासत्व सहित मानव बेचबिखनका सबै रूपहरूलाई आपराधिक ठहराउँदछ। ऐनले बेचबिखनलाई शोषणको उद्देश्यका लागि जबरजस्ती, बल, धोखाधडी, छल वा सत्ताको दुरुपयोगमार्फत व्यक्तिहरूको भर्ती, ढुवानी, हस्तान्तरण, लुकाउने वा प्राप्त गर्ने गरी परिभाषित गर्दछ। यी मध्ये कुनै पनि माध्यम प्रयोग गरिएको अवस्थामा पीडितको सहमति अप्रासंगिक हुन्छ। महिला र बालबालिका बेचबिखनको लागि सबैभन्दा संवेदनशील भएकाले तिनीहरूको लागि विशेष व्यवस्थाहरू छन्। राष्ट्रिय मानव अधिकार आयोग र महिला, बालबालिका तथा ज्येष्ठ नागरिक मन्त्रालयले बेचबिखनविरोधी प्रयासहरूको समन्वय गर्दछ। बेचबिखनको सजाय दस देखि बीस वर्षसम्म कैद र पाँच लाख रुपैयाँसम्म जरिवाना हुन सक्छ। बेचबिखनका पीडितहरू संरक्षण, आश्रय, चिकित्सा हेरचाह, परामर्श, कानूनी सहायता र क्षतिपूर्तिको हकदार हुन्छन्। ऐनले यौन पर्यटन प्रवर्धन र बेचबिखनको लागि विज्ञापन प्रकाशनलाई पनि आपराधिक ठहराउँदछ।',
      keywords: ['human trafficking', 'forced labor', 'sexual exploitation', 'manav bechbikhan', 'human rights commission', 'victim protection', 'osarapasar', 'trafficking prevention'],
    ),
    LegalDocument(
      id: 'hr_003',
      titleEn: 'Women Rights and Gender Equality',
      titleNp: 'महिला अधिकार र लैङ्गिक समानता',
      category: 'Human Rights',
      contentEn: 'The Constitution of Nepal guarantees women equal rights to lineage, property, and participation in all spheres of life. The Gender Equality Act and various sectoral laws prohibit discrimination against women in employment, education, and public life. Women have the right to equal pay for equal work, maternity benefits, and safe working conditions. The act mandates at least one-third representation of women in all state mechanisms, including the Federal Parliament, Provincial Assemblies, and Local Councils. Women have equal rights to inherit ancestral property, and daughters have the same rights as sons in parental property. The act on sexual harassment provides a safe working environment for women and mechanisms for redress. Domestic violence against women is a criminal offense. The Ministry of Women, Children and Senior Citizens formulates policies for women empowerment. Special provisions exist for women in custody, including separate prison facilities and protection from strip searches by male officers.',
      contentNp: 'नेपालको संविधानले महिलालाई वंश, सम्पत्ति र जीवनका सबै क्षेत्रमा सहभागिताको समान अधिकारको ग्यारेन्टी गर्दछ। लैङ्गिक समानता ऐन र विभिन्न क्षेत्रगत कानूनहरूले रोजगारी, शिक्षा र सार्वजनिक जीवनमा महिलाविरुद्ध भेदभावलाई निषेध गर्दछ। महिलालाई समान कामको लागि समान ज्याला, सुत्केरी लाभ र सुरक्षित काम गर्ने अवस्थाको अधिकार छ। ऐनले संघीय संसद्, प्रदेशसभा र स्थानीय परिषद् सहित सबै राज्य संयन्त्रमा कम्तीमा एक तिहाइ महिला सहभागिता अनिवार्य गरेको छ। महिलालाई पुर्खौली सम्पत्तिमा समान अधिकार छ, र छोरीहरूलाई आमाबाबुको सम्पत्तिमा छोराको समान अधिकार छ। यौन उत्पीडन सम्बन्धी ऐनले महिलाको लागि सुरक्षित काम गर्ने वातावरण र उपचारको संयन्त्र प्रदान गर्दछ। महिलाविरुद्ध घरेलु हिंसा आपराधिक अपराध हो। महिला, बालबालिका तथा ज्येष्ठ नागरिक मन्त्रालयले महिला सशक्तीकरणको लागि नीति बनाउँदछ। हिरासतमा रहेका महिलाको लागि पृथक कारागार सुविधा र पुरुष अधिकारीद्वारा स्ट्रिप खोजीबाट संरक्षण सहित विशेष व्यवस्थाहरू छन्।',
      keywords: ['women rights', 'gender equality', 'sexual harassment', 'equal pay', 'mahila adhikar', 'laingik samanta', 'property rights', 'maternity benefit'],
    ),
    LegalDocument(
      id: 'hr_004',
      titleEn: 'Rights of Persons with Disabilities',
      titleNp: 'अपाङ्गता भएका व्यक्तिहरूको अधिकार',
      category: 'Human Rights',
      contentEn: 'The Rights of Persons with Disabilities Act of Nepal guarantees the rights and dignity of persons with disabilities. The act recognizes physical, visual, hearing, speech, intellectual, psycho-social, and multiple disabilities. Persons with disabilities have the right to accessible environments, inclusive education, employment, health services, and participation in cultural life. The state is obligated to provide reasonable accommodation in public buildings, transportation, and information systems. At least five percent of government jobs are reserved for persons with disabilities. Educational institutions must provide inclusive education with appropriate support. The act mandates the use of sign language, braille, and accessible formats in official communications. Public buildings must have ramps, accessible toilets, and other facilities. The National Federation of the Disabled Nepal and the Ministry of Women, Children and Senior Citizens work for the empowerment of persons with disabilities. Discrimination against persons with disabilities is prohibited and punishable by law.',
      contentNp: 'नेपालको अपाङ्गता भएका व्यक्तिको अधिकार ऐनले अपाङ्गता भएका व्यक्तिहरूको अधिकार र मर्यादाको ग्यारेन्टी गर्दछ। ऐनले शारीरिक, दृष्टि, श्रवण, वाणी, बौद्धिक, मनोसामाजिक र बहु-अपाङ्गतालाई मान्यता दिन्छ। अपाङ्गता भएका व्यक्तिहरूलाई पहुँचयोग्य वातावरण, समावेशी शिक्षा, रोजगारी, स्वास्थ्य सेवा र सांस्कृतिक जीवनमा सहभागिताको अधिकार छ। राज्य सार्वजनिक भवन, यातायात र सूचना प्रणालीमा उचित पहुँच सुविधा प्रदान गर्न बाध्य छ। कम्तीमा पाँच प्रतिशत सरकारी जागिर अपाङ्गता भएका व्यक्तिहरूको लागि आरक्षित छ। शैक्षिक संस्थाहरूले उपयुक्त सहयोगसहित समावेशी शिक्षा प्रदान गर्नुपर्दछ। ऐनले आधिकारिक सञ्चारमा सांकेतिक भाषा, ब्रेल र पहुँचयोग्य ढाँचाको प्रयोग अनिवार्य गरेको छ। सार्वजनिक भवनहरूमा र्याम्प, पहुँचयोग्य शौचालय र अन्य सुविधाहरू हुनुपर्दछ। राष्ट्रिय अपाङ्ग महासंघ नेपाल र महिला, बालबालिका तथा ज्येष्ठ नागरिक मन्त्रालयले अपाङ्गता भएका व्यक्तिहरूको सशक्तीकरणको लागि काम गर्दछ। अपाङ्गता भएका व्यक्तिहरूविरुद्ध भेदभाव निषेधित छ र कानूनद्वारा दण्डनीय छ।',
      keywords: ['disability rights', 'inclusive education', 'accessible environment', 'sign language', 'apangata adhikar', 'braille', 'reasonable accommodation', 'accessibility'],
    ),
    LegalDocument(
      id: 'hr_005',
      titleEn: 'Right to Health and Healthcare Access',
      titleNp: 'स्वास्थ्यको हक र स्वास्थ्य सेवा पहुँच',
      category: 'Human Rights',
      contentEn: 'The Constitution of Nepal guarantees every citizen the right to free basic health services from the state. The Public Health Service Act establishes the framework for the delivery of health services and the rights of patients. Every person has the right to access health services without discrimination. The state is responsible for ensuring the availability of essential medicines, vaccines, and medical supplies in all public health facilities. Patients have the right to informed consent, confidentiality of medical information, and dignity during treatment. The act provides for the regulation of private health institutions to ensure quality and prevent overcharging. Maternal health services, including prenatal care, safe delivery services, and postnatal care, are provided free of cost at public facilities. Health insurance programs are available for vulnerable populations. The Ministry of Health and Population formulates national health policies and programs. Medical negligence is a punishable offense, and victims may claim compensation.',
      contentNp: 'नेपालको संविधानले प्रत्येक नागरिकलाई राज्यबाट निःशुल्क आधारभूत स्वास्थ्य सेवाको हकको ग्यारेन्टी गर्दछ। सार्वजनिक स्वास्थ्य सेवा ऐनले स्वास्थ्य सेवा प्रवाह र बिरामीको अधिकारको लागि ढाँचा स्थापित गर्दछ। प्रत्येक व्यक्तिलाई भेदभावविना स्वास्थ्य सेवामा पहुँच पाउने अधिकार छ। राज्य सबै सार्वजनिक स्वास्थ्य संस्थाहरूमा आवश्यक औषधि, खोप र चिकित्सा आपूर्तिको उपलब्धता सुनिश्चित गर्न जिम्मेवार छ। बिरामीहरूलाई सूचित सहमति, चिकित्सा जानकारीको गोपनीयता र उपचारको क्रममा मर्यादाको अधिकार छ। ऐनले गुणस्तर सुनिश्चित गर्न र अत्यधिक शुल्क रोक्न निजी स्वास्थ्य संस्थाहरूको नियमनको व्यवस्था गरेको छ। प्रसवपूर्व हेरचाह, सुरक्षित प्रसव सेवा र प्रसवपछिको हेरचाह सहित मातृ स्वास्थ्य सेवा सार्वजनिक संस्थाहरूमा निःशुल्क प्रदान गरिन्छ। कमजोर जनसंख्याको लागि स्वास्थ्य बीमा कार्यक्रमहरू उपलब्ध छन्। स्वास्थ्य तथा जनसङ्ख्या मन्त्रालयले राष्ट्रिय स्वास्थ्य नीति र कार्यक्रमहरू बनाउँदछ। चिकित्सा लापरवाही दण्डनीय अपराध हो, र पीडितहरूले क्षतिपूर्ति दाबी गर्न सक्छन्।',
      keywords: ['right to health', 'healthcare', 'health insurance', 'maternal health', 'swasthya ko hak', 'public health', 'medical negligence', 'essential medicines'],
    ),

    // ===== TECHNOLOGY LAW (4) =====
    LegalDocument(
      id: 'tech_001',
      titleEn: 'Electronic Transactions and Digital Signatures',
      titleNp: 'विद्युतीय कारोबार र डिजिटल हस्ताक्षर',
      category: 'Technology Law',
      contentEn: 'The Electronic Transactions Act of Nepal provides legal recognition for electronic records and digital signatures. Electronic records are admissible as evidence in legal proceedings and have the same legal effect as paper documents. A digital signature is legally valid if it is created using a secure electronic signature method and verified through a public key infrastructure. The Controller of Certifying Authorities licenses and regulates certifying authorities who issue digital signature certificates. The act establishes the legal framework for e-commerce, including the formation of contracts online, liability of service providers, and consumer protection in electronic transactions. Electronic records stored in a computer system are considered admissible evidence if they meet the requirements of the Evidence Act. The government may specify the types of documents that require physical signatures and cannot be executed electronically. The act also addresses the retention of electronic records and the obligations of intermediaries.',
      contentNp: 'नेपालको विद्युतीय कारोबार ऐनले विद्युतीय अभिलेख र डिजिटल हस्ताक्षरको लागि कानूनी मान्यता प्रदान गर्दछ। विद्युतीय अभिलेखहरू कानूनी कारबाहीमा प्रमाणको रूपमा स्वीकार्य छन् र कागजातको समान कानूनी प्रभाव हुन्छ। डिजिटल हस्ताक्षर कानूनी रूपमा वैध हुन्छ यदि यो सुरक्षित विद्युतीय हस्ताक्षर विधि प्रयोग गरी सिर्जना गरिएको र सार्वजनिक कुञ्जी पूर्वाधारमार्फत प्रमाणित गरिएको छ। प्रमाणीकरण अधिकारीहरूको नियन्त्रकले डिजिटल हस्ताक्षर प्रमाणपत्र जारी गर्ने प्रमाणीकरण अधिकारीहरूलाई इजाजतपत्र दिन्छ र नियमन गर्दछ। ऐनले अनलाइन सम्झौता गठन, सेवा प्रदायकको दायित्व, र विद्युतीय कारोबारमा उपभोक्ता संरक्षण सहित इ-कमर्सको लागि कानूनी ढाँचा स्थापित गर्दछ। कम्प्युटर प्रणालीमा भण्डारण गरिएको विद्युतीय अभिलेखहरू प्रमाण ऐनको आवश्यकता पूरा गरेमा स्वीकार्य प्रमाण मानिन्छन्। सरकारले भौतिक हस्ताक्षर आवश्यक हुने र विद्युतीय रूपमा कार्यान्वयन गर्न नसकिने कागजातका प्रकारहरू निर्दिष्ट गर्न सक्छ। ऐनले विद्युतीय अभिलेखको अभिधारण र मध्यस्थकर्ताहरूको दायित्व पनि सम्बोधन गर्दछ।',
      keywords: ['electronic transactions', 'digital signature', 'e-commerce', 'certifying authority', 'bidyuti karobar', 'digital signature certificate', 'electronic evidence', 'public key infrastructure'],
    ),
    LegalDocument(
      id: 'tech_002',
      titleEn: 'Copyright and Creative Works Protection',
      titleNp: 'प्रतिलिपि अधिकार र सिर्जनात्मक कार्य संरक्षण',
      category: 'Technology Law',
      contentEn: 'The Copyright Act of Nepal protects the rights of authors, artists, musicians, filmmakers, and other creators over their original works. Copyright protection extends to literary works, musical compositions, dramatic works, artistic works, cinematographic films, sound recordings, broadcasts, and computer programs. The author has the exclusive right to reproduce, distribute, perform, display, and create derivative works based on their original creation. Copyright is automatically granted upon creation of the work and does not require registration. However, registration with the Copyright Registrar provides prima facie evidence in infringement cases. The duration of copyright is the life of the author plus fifty years after death. For works with multiple authors, the term is measured from the death of the last surviving author. Fair use provisions allow limited use of copyrighted works for education, research, criticism, and news reporting without permission. Infringement may result in civil remedies and criminal penalties including fines and imprisonment.',
      contentNp: 'नेपालको प्रतिलिपि अधिकार ऐनले लेखक, कलाकार, सङ्गीतकार, चलचित्र निर्माता र अन्य सिर्जनाकर्ताहरूको उनीहरूको मौलिक कार्यहरूमाथिको अधिकारको संरक्षण गर्दछ। प्रतिलिपि अधिकार संरक्षण साहित्यिक कार्य, साङ्गीतिक रचना, नाटकीय कार्य, कलात्मक कार्य, चलचित्र, ध्वनि अभिलेखन, प्रसारण र कम्प्युटर प्रोग्रामहरूमा विस्तारित हुन्छ। लेखकसँग आफ्नो मौलिक सिर्जनाको आधारमा पुनरुत्पादन, वितरण, प्रदर्शन, प्रदर्शन र व्युत्पन्न कार्यहरू सिर्जना गर्ने विशेष अधिकार हुन्छ। प्रतिलिपि अधिकार कार्यको सिर्जनापछि स्वचालित रूपमा प्रदान हुन्छ र यसको लागि दर्ता आवश्यक पर्दैन। तथापि, प्रतिलिपि अधिकार रजिष्ट्रारमा दर्ता गरेमा उल्लङ्घनको मुद्दामा प्रारम्भिक प्रमाण प्रदान गर्दछ। प्रतिलिपि अधिकारको अवधि लेखकको जीवनकाल र मृत्युपछि थप पचास वर्ष हो। बहु लेखक भएका कार्यहरूको लागि, अवधि अन्तिम जीवित लेखकको मृत्युबाट गणना गरिन्छ। उचित प्रयोग व्यवस्थाले अनुमतिविना शिक्षा, अनुसन्धान, आलोचना र समाचार रिपोर्टिङको लागि प्रतिलिपि अधिकार भएका कार्यहरूको सीमित प्रयोगको अनुमति दिन्छ। उल्लङ्घनले जरिवाना र कैद सहित नागरिक उपचार र आपराधिक दण्डको परिणाम हुन सक्छ।',
      keywords: ['copyright', 'creative works', 'fair use', 'author rights', 'pratilipi adhikar', 'copyright registration', 'intellectual property', 'infringement'],
    ),
    LegalDocument(
      id: 'tech_003',
      titleEn: 'Data Protection and Privacy Law',
      titleNp: 'डाटा संरक्षण र गोपनीयता कानून',
      category: 'Technology Law',
      contentEn: 'The Data Protection Act of Nepal establishes the legal framework for the collection, processing, storage, and transfer of personal data. The act applies to both public and private entities that process personal data. Personal data can only be collected for specified, explicit, and legitimate purposes and must be processed fairly and transparently. Data subjects have the right to access their personal data, request correction of inaccurate data, and object to the processing of their data for direct marketing. Consent must be obtained before collecting sensitive personal data. Organizations must implement appropriate technical and organizational measures to protect personal data against unauthorized access, loss, or destruction. Cross-border transfer of personal data is restricted to jurisdictions with adequate data protection standards. The act establishes a Data Protection Authority to oversee compliance and investigate complaints. Violations may result in fines of up to one million rupees and imprisonment. Data breach notification to affected individuals is mandatory.',
      contentNp: 'नेपालको डाटा संरक्षण ऐनले व्यक्तिगत डाटा सङ्कलन, प्रशोधन, भण्डारण र हस्तान्तरणको लागि कानूनी ढाँचा स्थापित गर्दछ। ऐन व्यक्तिगत डाटा प्रशोधन गर्ने सार्वजनिक र निजी दुवै संस्थाहरूमा लागू हुन्छ। व्यक्तिगत डाटा निर्दिष्ट, स्पष्ट र वैध उद्देश्यका लागि मात्र सङ्कलन गर्न सकिन्छ र निष्पक्ष र पारदर्शी रूपमा प्रशोधन गरिनुपर्दछ। डाटा विषयहरूले आफ्नो व्यक्तिगत डाटामा पहुँच पाउने, गलत डाटा सच्याउन अनुरोध गर्ने र प्रत्यक्ष मार्केटिङको लागि आफ्नो डाटा प्रशोधनमा आपत्ति जनाउने अधिकार छ। संवेदनशील व्यक्तिगत डाटा सङ्कलन गर्नुअघि सहमति प्राप्त गर्नुपर्दछ। संस्थाहरूले व्यक्तिगत डाटालाई अनाधिकृत पहुँच, हानि वा विनाशबाट जोगाउन उपयुक्त प्राविधिक र संगठनात्मक उपायहरू कार्यान्वयन गर्नुपर्दछ। व्यक्तिगत डाटाको सीमापार हस्तान्तरण पर्याप्त डाटा संरक्षण मापदण्ड भएका क्षेत्राधिकारहरूमा मात्र सीमित छ। ऐनले अनुपालनको सुपरीवेक्षण गर्न र उजुरीहरूको अनुसन्धान गर्न डाटा संरक्षण प्राधिकरण स्थापना गर्दछ। उल्लङ्घनको परिणाम दश लाख रुपैयाँसम्म जरिवाना र कैद हुन सक्छ। प्रभावित व्यक्तिहरूलाई डाटा उल्लङ्घनको सूचना अनिवार्य छ।',
      keywords: ['data protection', 'privacy', 'personal data', 'consent', 'data protection authority', 'gopaniyata', 'cross-border transfer', 'data breach'],
    ),
    LegalDocument(
      id: 'tech_004',
      titleEn: 'Social Media and Online Content Regulation',
      titleNp: 'सामाजिक सञ्जाल र अनलाइन सामग्री नियमन',
      category: 'Technology Law',
      contentEn: 'The Social Media Regulation Act of Nepal governs the operation of social media platforms and the dissemination of content online. Social media platforms operating in Nepal must register with the government and establish a physical presence in the country. Platforms are required to remove illegal content, including hate speech, defamatory material, incitement to violence, and content that threatens national security within twenty-four hours of notification. The act mandates transparency in content moderation algorithms and advertising practices. Users must verify their identity through a registered mobile number or citizenship details to create accounts. Social media companies must establish grievance redressal mechanisms for users in Nepal. The spread of false or misleading information is a punishable offense. The government may block access to content or entire platforms that violate Nepali law. The act balances the right to freedom of expression with the need to maintain public order and protect users from harmful content. Penalties for non-compliance include fines and imprisonment.',
      contentNp: 'नेपालको सामाजिक सञ्जाल नियमन ऐनले सामाजिक सञ्जाल प्लेटफर्महरूको सञ्चालन र अनलाइन सामग्रीको प्रसारलाई नियमन गर्दछ। नेपालमा सञ्चालित सामाजिक सञ्जाल प्लेटफर्महरूले सरकारमा दर्ता गर्नुपर्दछ र देशमा भौतिक उपस्थिति स्थापित गर्नुपर्दछ। प्लेटफर्महरूले सूचना प्राप्त भएको चौबीस घण्टाभित्र घृणायुक्त भाषण, मानहानिकारक सामग्री, हिंसाको उक्साहट र राष्ट्रिय सुरक्षालाई खतरा पुर्याउने सामग्री सहित गैरकानूनी सामग्री हटाउन आवश्यक छ। ऐनले सामग्री मध्यस्थता एल्गोरिदम र विज्ञापन अभ्यासहरूमा पारदर्शिता अनिवार्य गरेको छ। प्रयोगकर्ताहरूले खाता सिर्जना गर्न दर्ता गरिएको मोबाइल नम्बर वा नागरिकता विवरणमार्फत आफ्नो पहिचान प्रमाणित गर्नुपर्दछ। सामाजिक सञ्जाल कम्पनीहरूले नेपालका प्रयोगकर्ताहरूको लागि उजुरी समाधान संयन्त्र स्थापित गर्नुपर्दछ। झूटो वा भ्रामक जानकारीको प्रसार दण्डनीय अपराध हो। सरकारले नेपाली कानून उल्लङ्घन गर्ने सामग्री वा सम्पूर्ण प्लेटफर्महरूमा पहुँच रोक्न सक्छ। ऐनले अभिव्यक्ति स्वतन्त्रताको हकलाई सार्वजनिक व्यवस्था कायम राख्न र प्रयोगकर्ताहरूलाई हानिकारक सामग्रीबाट जोगाउन आवश्यकतासँग सन्तुलन गर्दछ। गैर-अनुपालनको लागि जरिवाना र कैद सहित दण्डको व्यवस्था छ।',
      keywords: ['social media', 'online content', 'hate speech', 'content moderation', 'samajik sanjal', 'platform regulation', 'grievance redressal', 'misinformation'],
    ),

    // ===== ENVIRONMENT LAW (4) =====
    LegalDocument(
      id: 'env_001',
      titleEn: 'Environmental Conservation and Protection',
      titleNp: 'वातावरण संरक्षण र संरक्षा',
      category: 'Environment Law',
      contentEn: 'The Environment Protection Act of Nepal establishes the legal framework for the conservation and protection of the environment. The act requires an Environmental Impact Assessment (EIA) for any development project that may significantly affect the environment. Projects classified as having potential environmental impacts must prepare an EIA report and obtain approval from the Ministry of Environment. The EIA process includes public participation, baseline studies, impact prediction, mitigation measures, and monitoring plans. The act also requires Initial Environmental Examination (IEE) for smaller projects. The government has the power to designate protected areas, including national parks, wildlife reserves, conservation areas, and buffer zones. Activities such as mining, deforestation, and industrial discharge are regulated to prevent environmental degradation. The polluter pays principle is recognized, requiring those who cause environmental damage to bear the cost of remediation. Penalties for violations include fines, imprisonment, and orders for restoration.',
      contentNp: 'नेपालको वातावरण संरक्षण ऐनले वातावरणको संरक्षण र संरक्षाको लागि कानूनी ढाँचा स्थापित गर्दछ। ऐनले वातावरणमा महत्त्वपूर्ण प्रभाव पार्न सक्ने कुनै पनि विकास परियोजनाको लागि वातावरणीय प्रभाव मूल्याङ्कन (ईआईए) आवश्यक गर्दछ। सम्भावित वातावरणीय प्रभाव भएको वर्गीकृत परियोजनाहरूले ईआईए प्रतिवेदन तयार गर्नुपर्दछ र वातावरण मन्त्रालयबाट स्वीकृति लिनुपर्दछ। ईआईए प्रक्रियामा सार्वजनिक सहभागिता, आधारभूत अध्ययन, प्रभाव भविष्यवाणी, न्यूनीकरण उपाय र अनुगमन योजना समावेश हुन्छ। ऐनले साना परियोजनाहरूको लागि प्रारम्भिक वातावरणीय परीक्षण (आईईई) पनि आवश्यक गर्दछ। सरकारलाई राष्ट्रिय निकुञ्ज, वन्यजन्तु आरक्ष, संरक्षण क्षेत्र र मध्यवर्ती क्षेत्र सहित संरक्षित क्षेत्र निर्धारण गर्ने अधिकार छ। खानी, वन फँडानी र औद्योगिक प्रवाह जस्ता गतिविधिहरू वातावरणीय ह्रास रोक्न नियमन गरिन्छ। प्रदूषक तिर्ने सिद्धान्त मान्यता प्राप्त छ, जसले वातावरणीय क्षति पुर्याउनेहरूलाई सुधारको लागत वहन गर्न आवश्यक गर्दछ। उल्लङ्घनको लागि जरिवाना, कैद र पुनर्स्थापनाको आदेश सहित दण्डको व्यवस्था छ।',
      keywords: ['environment protection', 'environmental impact assessment', 'EIA', 'vatavaran sanrakshan', 'polluter pays', 'protected areas', 'national park', 'mitigation'],
    ),
    LegalDocument(
      id: 'env_002',
      titleEn: 'Forest Conservation and Management',
      titleNp: 'वन संरक्षण र व्यवस्थापन',
      category: 'Environment Law',
      contentEn: 'The Forest Act of Nepal governs the conservation, management, and utilization of forests in Nepal. Forests are classified as national forests, community forests, religious forests, private forests, and protected forests. Community forestry is a successful model in Nepal where local communities manage forests and receive benefits from forest products. The act requires a management plan for the sustainable use of forest resources. Prohibited activities include illegal logging, encroachment, forest fires, and poaching. The government may declare any area as a protected forest to conserve biodiversity and watersheds. Timber harvesting requires a permit, and transportation of timber requires documentation. The Department of Forests is responsible for the implementation of forest laws and policies. The act also provides for the establishment of botanical gardens, arboretums, and tree nurseries. The forest offense penalties include fines, confiscation of equipment, and imprisonment. The community forestry program has contributed significantly to forest restoration and poverty reduction.',
      contentNp: 'नेपालको वन ऐनले नेपालमा वनको संरक्षण, व्यवस्थापन र उपयोगलाई नियमन गर्दछ। वनलाई राष्ट्रिय वन, सामुदायिक वन, धार्मिक वन, निजी वन र संरक्षित वनको रूपमा वर्गीकृत गरिन्छ। सामुदायिक वन नेपालमा सफल मोडेल हो जहाँ स्थानीय समुदायले वन व्यवस्थापन गर्दछ र वन उत्पादनबाट लाभ प्राप्त गर्दछ। ऐनले वन स्रोतको दिगो उपयोगको लागि व्यवस्थापन योजना आवश्यक गर्दछ। निषेधित गतिविधिहरूमा अवैध कटान, अतिक्रमण, वन डढेलो र शिकार समावेश छन्। सरकारले जैविक विविधता र जलाधार संरक्षणको लागि कुनै पनि क्षेत्रलाई संरक्षित वन घोषित गर्न सक्छ। काठ फँडानीको लागि अनुमति आवश्यक छ, र काठ ढुवानीको लागि कागजात आवश्यक छ। वन विभाग वन कानून र नीतिहरूको कार्यान्वयनको लागि जिम्मेवार छ। ऐनले वनस्पति उद्यान, वृक्षारोपण र वृक्ष नर्सरीहरू स्थापनाको पनि व्यवस्था गरेको छ। वन अपराधको लागि जरिवाना, उपकरण जफत र कैद सहित दण्डको व्यवस्था छ। सामुदायिक वन कार्यक्रमले वन पुनर्स्थापना र गरिबी न्यूनीकरणमा महत्त्वपूर्ण योगदान पुर्याएको छ।',
      keywords: ['forest conservation', 'community forestry', 'illegal logging', 'ban sanrakshan', 'samudayik ban', 'timber permit', 'protected forest', 'deforestation'],
    ),
    LegalDocument(
      id: 'env_003',
      titleEn: 'Water Resources and Pollution Control',
      titleNp: 'जल स्रोत र प्रदूषण नियन्त्रण',
      category: 'Environment Law',
      contentEn: 'The Water Resources Act of Nepal governs the utilization, conservation, and management of water resources. Water resources are the property of the state, and their use requires a license from the relevant authority. The act covers the use of water for drinking, irrigation, hydropower, industrial purposes, navigation, and recreation. Priority is given to drinking water and domestic use over other uses. The Water Pollution Control Act prohibits the discharge of pollutants into water bodies beyond prescribed standards. Industries and municipalities must treat their wastewater before discharge. The act establishes water quality standards and monitoring mechanisms. The government may designate water pollution control areas and impose restrictions on activities that cause pollution. Penalties for water pollution include fines, closure of facilities, and imprisonment. The act also provides for the establishment of watershed management committees. Nepal abundance of water resources from rivers and glaciers requires careful management to ensure sustainability and equitable distribution.',
      contentNp: 'नेपालको जल स्रोत ऐनले जल स्रोतको उपयोग, संरक्षण र व्यवस्थापनलाई नियमन गर्दछ। जल स्रोत राज्यको सम्पत्ति हो, र यसको प्रयोगको लागि सम्बन्धित निकायबाट इजाजतपत्र आवश्यक हुन्छ। ऐनले खानेपानी, सिँचाइ, जलविद्युत, औद्योगिक उद्देश्य, नौवहन र मनोरञ्जनको लागि पानीको प्रयोग समावेश गर्दछ। खानेपानी र घरेलु प्रयोगलाई अन्य प्रयोगभन्दा प्राथमिकता दिइन्छ। जल प्रदूषण नियन्त्रण ऐनले निर्धारित मापदण्डभन्दा बढी जल निकायमा प्रदूषक फाल्न निषेध गर्दछ। उद्योग र नगरपालिकाहरूले फाल्नुअघि आफ्नो फोहोर पानी प्रशोधन गर्नुपर्दछ। ऐनले पानीको गुणस्तर मापदण्ड र अनुगमन संयन्त्र स्थापित गर्दछ। सरकारले जल प्रदूषण नियन्त्रण क्षेत्र निर्धारण गर्न र प्रदूषण गराउने गतिविधिहरूमा प्रतिबन्ध लगाउन सक्छ। जल प्रदूषणको लागि जरिवाना, सुविधा बन्द र कैद सहित दण्डको व्यवस्था छ। ऐनले जलाधार व्यवस्थापन समितिहरू स्थापनाको पनि व्यवस्था गरेको छ। नेपालको नदी र हिमनदीबाट प्रशस्त जल स्रोतले दिगो र समान वितरण सुनिश्चित गर्न सावधानीपूर्वक व्यवस्थापन आवश्यक गर्दछ।',
      keywords: ['water resources', 'water pollution', 'wastewater treatment', 'jal srot', 'jal pradushan', 'water license', 'hydropower', 'watershed management'],
    ),
    LegalDocument(
      id: 'env_004',
      titleEn: 'Climate Change and Sustainable Development',
      titleNp: 'जलवायु परिवर्तन र दिगो विकास',
      category: 'Environment Law',
      contentEn: 'The Climate Change Policy of Nepal addresses the impacts of climate change and promotes low-carbon, climate-resilient development. Nepal is highly vulnerable to climate change due to its fragile geography and dependence on natural resources. Key impacts include glacial melting, changing monsoon patterns, increased flooding and landslides, and reduced agricultural productivity. The National Adaptation Program of Action identifies priority adaptation needs, including food security, water resources, health, disaster risk reduction, and biodiversity conservation. The government has established the Climate Change Management Division and the REDD Implementation Centre to coordinate climate actions. Local adaptation plans of action are developed at the community level. The policy promotes renewable energy, energy efficiency, and sustainable transport as mitigation measures. Nepal is a party to the United Nations Framework Convention on Climate Change and the Paris Agreement. The government provides incentives for clean technology adoption and carbon trading.',
      contentNp: 'नेपालको जलवायु परिवर्तन नीतिले जलवायु परिवर्तनको प्रभावलाई सम्बोधन गर्दछ र कम-कार्बन, जलवायु-सहनशील विकासलाई प्रवर्धन गर्दछ। नेपाल यसको कमजोर भौगोलिक अवस्था र प्राकृतिक स्रोतमा निर्भरताका कारण जलवायु परिवर्तनको लागि अति जोखिमपूर्ण छ। मुख्य प्रभावहरूमा हिमनदी पग्लने, मनसुनको ढाँचा परिवर्तन, बाढी र पहिरो बढ्ने र कृषि उत्पादकत्व घट्ने समावेश छन्। राष्ट्रिय अनुकूलन कार्यक्रमले खाद्य सुरक्षा, जल स्रोत, स्वास्थ्य, विपद् जोखिम न्यूनीकरण र जैविक विविधता संरक्षण सहित प्राथमिकताका अनुकूलन आवश्यकताहरू पहिचान गर्दछ। सरकारले जलवायु परिवर्तन व्यवस्थापन प्रभाग र रेड कार्यान्वयन केन्द्र स्थापना गरेको छ। समुदाय स्तरमा स्थानीय अनुकूलन कार्ययोजनाहरू विकसित गरिन्छ। नीतिले न्यूनीकरण उपायको रूपमा नवीकरणीय ऊर्जा, ऊर्जा दक्षता र दिगो यातायातलाई प्रवर्धन गर्दछ। नेपाल जलवायु परिवर्तनसम्बन्धी संयुक्त राष्ट्रसंघीय ढाँचा अभिसमय र पेरिस सम्झौताको पक्ष राष्ट्र हो। सरकारले स्वच्छ प्रविधि अपनाउन र कार्बन व्यापारको लागि प्रोत्साहन प्रदान गर्दछ।',
      keywords: ['climate change', 'adaptation', 'sustainable development', 'jalabayu parivartan', 'greenhouse gas', 'renewable energy', 'carbon trading', 'disaster risk reduction'],
    ),

    // ===== EDUCATION LAW (4) =====
    LegalDocument(
      id: 'edu_001',
      titleEn: 'School Education and Curriculum Framework',
      titleNp: 'विद्यालय शिक्षा र पाठ्यक्रम ढाँचा',
      category: 'Education Law',
      contentEn: 'The Education Act of Nepal governs the establishment, operation, and management of schools. School education is divided into basic education (grades 1-8) and secondary education (grades 9-12). Basic education is compulsory and free in public schools. The government bears the cost of tuition, textbooks, and educational materials for basic education. The Curriculum Development Centre prepares the national curriculum framework, which includes core subjects such as Nepali, English, Mathematics, Science, Social Studies, and local subjects. Schools must follow the prescribed curriculum and obtain approval for any additional courses. The school management committee, composed of parents, teachers, and community members, oversees the management of the school. The Teacher Service Commission recruits teachers through competitive examinations. Private schools must meet minimum infrastructure and quality standards to obtain registration. The act prohibits corporal punishment and discrimination in schools. The Ministry of Education formulates policies and sets quality standards.',
      contentNp: 'नेपालको शिक्षा ऐनले विद्यालयको स्थापना, सञ्चालन र व्यवस्थापनलाई नियमन गर्दछ। विद्यालय शिक्षा आधारभूत शिक्षा (कक्षा १-८) र माध्यमिक शिक्षा (कक्षा ९-१२) मा विभाजित छ। आधारभूत शिक्षा सार्वजनिक विद्यालयमा अनिवार्य र निःशुल्क छ। सरकारले आधारभूत शिक्षाको लागि शुल्क, पाठ्यपुस्तक र शैक्षिक सामग्रीको लागत वहन गर्दछ। पाठ्यक्रम विकास केन्द्रले राष्ट्रिय पाठ्यक्रम ढाँचा तयार गर्दछ, जसमा नेपाली, अङ्ग्रेजी, गणित, विज्ञान, सामाजिक अध्ययन र स्थानीय विषयहरू जस्ता मुख्य विषयहरू समावेश हुन्छन्। विद्यालयहरूले निर्धारित पाठ्यक्रम पालना गर्नुपर्दछ र कुनै पनि अतिरिक्त पाठ्यक्रमको लागि स्वीकृति लिनुपर्दछ। अभिभावक, शिक्षक र समुदायका सदस्यहरू मिलेको विद्यालय व्यवस्थापन समितिले विद्यालयको व्यवस्थापनको सुपरीवेक्षण गर्दछ। शिक्षक सेवा आयोगले प्रतिस्पर्धात्मक परीक्षामार्फत शिक्षक भर्ना गर्दछ। निजी विद्यालयहरूले दर्ताको लागि न्यूनतम पूर्वाधार र गुणस्तर मापदण्ड पूरा गर्नुपर्दछ। ऐनले विद्यालयमा शारीरिक दण्ड र भेदभावलाई निषेध गर्दछ। शिक्षा मन्त्रालयले नीति बनाउँदछ र गुणस्तर मापदण्ड निर्धारण गर्दछ।',
      keywords: ['school education', 'curriculum', 'basic education', 'vidyalaya shiksha', 'pathyakram', 'compulsory education', 'school management', 'teacher recruitment'],
    ),
    LegalDocument(
      id: 'edu_002',
      titleEn: 'University Education and Higher Education Regulation',
      titleNp: 'विश्वविद्यालय शिक्षा र उच्च शिक्षा नियमन',
      category: 'Education Law',
      contentEn: 'The University Act of Nepal governs the establishment and operation of universities and higher education institutions. Universities may be established by an act of Parliament and have the authority to award degrees, diplomas, and certificates. Each university has a Senate as its supreme academic body, an Executive Council for management, and an Academic Council for academic matters. The University Grants Commission allocates government funding to universities and ensures quality assurance through accreditation and evaluation. Higher education programs include bachelor, master, and doctoral degrees in various disciplines including arts, science, engineering, medicine, law, management, and education. Admission requirements, fee structures, and academic standards are set by each university within the national framework. The act provides for academic freedom, including freedom of teaching, research, and publication. Universities must establish research centers and promote innovation. The Quality Assurance and Accreditation Committee evaluates higher education institutions and awards accreditation status.',
      contentNp: 'नेपालको विश्वविद्यालय ऐनले विश्वविद्यालय र उच्च शिक्षा संस्थाहरूको स्थापना र सञ्चालनलाई नियमन गर्दछ। विश्वविद्यालयहरू संसद्को ऐनद्वारा स्थापना गर्न सकिन्छ र उपाधि, डिप्लोमा र प्रमाणपत्र प्रदान गर्ने अधिकार हुन्छ। प्रत्येक विश्वविद्यालयमा सर्वोच्च शैक्षिक निकायको रूपमा सिनेट, व्यवस्थापनको लागि कार्यकारी परिषद् र शैक्षिक मामिलाको लागि शैक्षिक परिषद् हुन्छ। विश्वविद्यालय अनुदान आयोगले विश्वविद्यालयहरूलाई सरकारी कोष विनियोजन गर्दछ र मान्यता र मूल्याङ्कनमार्फत गुणस्तर आश्वासन सुनिश्चित गर्दछ। उच्च शिक्षा कार्यक्रमहरूमा कला, विज्ञान, इन्जिनियरिङ, चिकित्सा, कानून, व्यवस्थापन र शिक्षा सहित विभिन्न विषयहरूमा स्नातक, स्नातकोत्तर र विद्यावारिधि डिग्रीहरू समावेश छन्। प्रवेश आवश्यकता, शुल्क संरचना र शैक्षिक मापदण्ड प्रत्येक विश्वविद्यालयले राष्ट्रिय ढाँचाभित्र निर्धारण गर्दछ। ऐनले शिक्षण, अनुसन्धान र प्रकाशनको स्वतन्त्रता सहित शैक्षिक स्वतन्त्रताको व्यवस्था गर्दछ। विश्वविद्यालयहरूले अनुसन्धान केन्द्रहरू स्थापना गर्नुपर्दछ र नवप्रवर्तनलाई प्रवर्धन गर्नुपर्दछ। गुणस्तर आश्वासन तथा मान्यता समितिले उच्च शिक्षा संस्थाहरूको मूल्याङ्कन गर्दछ र मान्यता स्थिति प्रदान गर्दछ।',
      keywords: ['university', 'higher education', 'accreditation', 'vishwavidyalaya', 'ugc', 'degree', 'academic freedom', 'quality assurance'],
    ),
    LegalDocument(
      id: 'edu_003',
      titleEn: 'Technical and Vocational Education',
      titleNp: 'प्राविधिक र व्यावसायिक शिक्षा',
      category: 'Education Law',
      contentEn: 'The Technical and Vocational Education Act of Nepal promotes skill development through technical and vocational education and training (TVET). The act establishes the Council for Technical Education and Vocational Training (CTEVT) as the apex body for TVET. CTEVT develops curricula, conducts examinations, awards certificates, and accredits training institutions. TVET programs include diploma and certificate courses in engineering, health, agriculture, forestry, information technology, tourism, and other trades. Apprenticeship programs combine on-the-job training with classroom instruction. The act emphasizes the involvement of the private sector in skill development through public-private partnerships. National skill standards are developed in consultation with industry bodies to ensure relevance. The Ministry of Education, Science and Technology oversees the implementation of TVET policies. The act also provides for the establishment of polytechnic institutes and technical schools. Skill testing and certification are conducted through the National Skill Testing Board. Financial assistance is available for students from disadvantaged communities.',
      contentNp: 'नेपालको प्राविधिक तथा व्यावसायिक शिक्षा ऐनले प्राविधिक र व्यावसायिक शिक्षा र तालिम (टिभिईटी) मार्फत सीप विकासलाई प्रवर्धन गर्दछ। ऐनले प्राविधिक शिक्षा तथा व्यावसायिक तालिम परिषद् (सिटिइभिटी) लाई टिभिईटीको सर्वोच्च निकायको रूपमा स्थापित गर्दछ। सिटिइभिटीले पाठ्यक्रम विकास गर्दछ, परीक्षा सञ्चालन गर्दछ, प्रमाणपत्र प्रदान गर्दछ र तालिम संस्थाहरूलाई मान्यता दिन्छ। टिभिईटी कार्यक्रमहरूमा इन्जिनियरिङ, स्वास्थ्य, कृषि, वन, सूचना प्रविधि, पर्यटन र अन्य सीपहरूमा डिप्लोमा र प्रमाणपत्र पाठ्यक्रमहरू समावेश छन्। प्रशिक्षुता कार्यक्रमहरूले काममा तालिमलाई कक्षा शिक्षासँग जोड्दछ। ऐनले सार्वजनिक-निजी साझेदारीमार्फत सीप विकासमा निजी क्षेत्रको सहभागितामा जोड दिन्छ। सान्दर्भिकता सुनिश्चित गर्न उद्योग निकायहरूसँगको परामर्शमा राष्ट्रिय सीप मापदण्डहरू विकसित गरिन्छ। शिक्षा, विज्ञान तथा प्रविधि मन्त्रालयले टिभिईटी नीतिहरूको कार्यान्वयनको सुपरीवेक्षण गर्दछ। ऐनले पोलिटेक्निक संस्था र प्राविधिक विद्यालयहरू स्थापनाको पनि व्यवस्था गरेको छ। राष्ट्रिय सीप परीक्षण बोर्डमार्फत सीप परीक्षण र प्रमाणीकरण गरिन्छ। विपन्न समुदायका विद्यार्थीहरूको लागि आर्थिक सहायता उपलब्ध छ।',
      keywords: ['technical education', 'vocational training', 'CTEVT', 'skill development', 'pravidhik shiksha', 'vyavsayik talim', 'apprenticeship', 'skill certification'],
    ),
    LegalDocument(
      id: 'edu_004',
      titleEn: 'Student Rights and Academic Discipline',
      titleNp: 'विद्यार्थी अधिकार र शैक्षिक अनुशासन',
      category: 'Education Law',
      contentEn: 'The Educational and Academic Discipline Act of Nepal defines the rights and responsibilities of students in educational institutions. Students have the right to quality education, a safe learning environment, access to library and laboratory facilities, and participation in extracurricular activities. Students may form student unions and associations as per the provisions of the act. The act prohibits ragging, bullying, and any form of harassment in educational institutions. Institutions must have a code of conduct for students and a disciplinary committee to address violations. Academic discipline includes regular attendance, completion of assignments, and adherence to examination rules. Cheating in examinations is a serious offense that may result in cancellation of results, suspension, or expulsion. The act also addresses the issue of student fees, prohibiting sudden increases and ensuring transparency. The scholarship and financial assistance system provides support to meritorious and needy students. The Student Welfare Fund is established in each institution for student welfare activities.',
      contentNp: 'नेपालको शैक्षिक तथा शैक्षणिक अनुशासन ऐनले शैक्षिक संस्थामा विद्यार्थीको अधिकार र उत्तरदायित्व परिभाषित गर्दछ। विद्यार्थीहरूलाई गुणस्तरीय शिक्षा, सुरक्षित सिकाइ वातावरण, पुस्तकालय र प्रयोगशाला सुविधामा पहुँच, र अतिरिक्त क्रियाकलापमा सहभागिताको अधिकार छ। विद्यार्थीहरूले ऐनको व्यवस्थाअनुसार विद्यार्थी सङ्घ र संघहरू गठन गर्न सक्छन्। ऐनले शैक्षिक संस्थामा र्यागिङ, बुलिङ र कुनै पनि प्रकारको उत्पीडनलाई निषेध गर्दछ। संस्थाहरूमा विद्यार्थीको लागि आचारसंहिता र उल्लङ्घन सम्बोधन गर्न अनुशासन समिति हुनुपर्दछ। शैक्षिक अनुशासनमा नियमित उपस्थिति, कार्यभार पूरा गर्ने र परीक्षा नियम पालना समावेश छ। परीक्षामा नक्कल गर्नु गम्भीर अपराध हो जसको परिणाम परिणाम रद्द, निलम्बन वा निष्कासन हुन सक्छ। ऐनले विद्यार्थी शुल्कको मुद्दालाई पनि सम्बोधन गर्दछ, अचानक वृद्धि निषेध गर्दछ र पारदर्शिता सुनिश्चित गर्दछ। छात्रवृत्ति र आर्थिक सहायता प्रणालीले प्रतिभाशाली र आवश्यकतामा परेका विद्यार्थीहरूलाई सहयोग प्रदान गर्दछ। प्रत्येक संस्थामा विद्यार्थी कल्याण गतिविधिको लागि विद्यार्थी कल्याण कोष स्थापना गरिन्छ।',
      keywords: ['student rights', 'academic discipline', 'ragging', 'scholarship', 'vidyarthi adhikar', 'shikshan anushasan', 'student union', 'examination rules'],
    ),
  
LegalDocument(
      id: 'pub_off_001',
      titleEn: 'Public Nuisance and Disorderly Conduct',
      titleNp: 'सार्वजनिक उपद्रव र अव्यवस्थित व्यवहार',
      category: 'Public Offenses Act',
      contentEn: 'Public nuisance includes any act that causes inconvenience, annoyance, or harm to the general public. Disorderly conduct includes fighting, using abusive language, creating excessive noise, and behaving in a manner that disturbs public peace. The Public Offenses Act empowers local authorities and police to take action against persons creating public nuisance. Penalties include fines, imprisonment, or both, depending on the severity of the offense.',
      contentNp: 'सार्वजनिक उपद्रवमा सर्वसाधारणलाई असुविधा, हैरानी वा हानि पुर्याउने कुनै पनि कार्य समावेश हुन्छ। अव्यवस्थित व्यवहारमा झगडा गर्ने, अपशब्द प्रयोग गर्ने, अत्यधिक आवाज गर्ने र सार्वजनिक शान्ति भङ्ग गर्ने व्यवहार समावेश हुन्छ। सार्वजनिक अपराध ऐनले स्थानीय अधिकारी र प्रहरीलाई सार्वजनिक उपद्रव गर्ने व्यक्तिविरुद्ध कारबाही गर्न अधिकार दिन्छ।',
      keywords: ['public nuisance', 'disorderly conduct', 'public peace', 'sarbajanik updrav', 'noise', 'abusive language'],
    ),

    LegalDocument(
      id: 'pub_off_002',
      titleEn: 'Defamation and Slander',
      titleNp: 'मानहानि र बदनामी',
      category: 'Public Offenses Act',
      contentEn: 'Defamation is the act of making false statements that harm the reputation of another person. In Nepalese law, defamation can be both a civil wrong and a criminal offense. Defamatory statements may be made orally (slander) or in writing (libel). The injured party may file a complaint in the criminal court and also claim civil damages. Truth is a valid defense in defamation cases if the statement was made in good faith and for the public benefit.',
      contentNp: 'मानहानि भनेको अर्को व्यक्तिको प्रतिष्ठालाई हानि पुर्याउने झूटा कथन गर्ने कार्य हो। नेपाली कानूनमा, मानहानि नागरिक गल्ती र फौजदारी अपराध दुवै हुन सक्छ। मानहानिकारक कथन मौखिक वा लिखित रूपमा गर्न सकिन्छ। पीडित पक्षले फौजदारी अदालतमा उजुरी दिन र नागरिक क्षतिपूर्ति पनि दाबी गर्न सक्छ।',
      keywords: ['defamation', 'slander', 'libel', 'reputation', 'manahani', 'badnami', 'good faith defense'],
    ),

    LegalDocument(
      id: 'pub_off_003',
      titleEn: 'Sedition and Treason',
      titleNp: 'राजद्रोह र राज्यविरुद्धको अपराध',
      category: 'Public Offenses Act',
      contentEn: 'Sedition is the act of promoting disaffection, hatred, or contempt against the government through spoken or written words. Treason involves acts of war against Nepal, attempting to overthrow the government by force, or providing aid to enemies of the state. These are serious offenses that threaten national security and are punishable by life imprisonment or the death penalty. Investigation of these offenses is conducted by specialized agencies.',
      contentNp: 'राजद्रोह भनेको मौखिक वा लिखित शब्दमार्फत सरकारविरुद्ध असंतोष, घृणा वा अवहेलना प्रवर्धन गर्ने कार्य हो। देशद्रोहमा नेपालविरुद्ध युद्ध गर्ने, बल प्रयोग गरी सरकार उखाल्ने प्रयास गर्ने वा राज्यको शत्रुलाई सहायता प्रदान गर्ने कार्य समावेश हुन्छ। यी गम्भीर अपराध हुन् जसले राष्ट्रिय सुरक्षालाई खतरामा पार्दछन्।',
      keywords: ['sedition', 'treason', 'rajdroh', 'national security', 'government overthrow', 'enemy aid'],
    ),

    LegalDocument(
      id: 'pub_off_004',
      titleEn: 'Counterfeit Currency and Forgery',
      titleNp: 'नक्कली मुद्रा र जालसाजी',
      category: 'Public Offenses Act',
      contentEn: 'The production, possession, or circulation of counterfeit currency is a serious criminal offense under Nepalese law. Forgery involves the creation or alteration of documents, signatures, or seals with the intent to defraud. Both offenses carry severe penalties including lengthy imprisonment and substantial fines. The Nepal Police and the Nepal Rastra Bank work together to investigate counterfeit currency cases. Digital forgery using technology is also covered under the Electronic Transactions Act.',
      contentNp: 'नक्कली मुद्राको उत्पादन, कब्जा वा प्रचलन नेपाली कानून अन्तर्गत गम्भीर फौजदारी अपराध हो। जालसाजीमा ठगी गर्ने आशयले कागजात, हस्ताक्षर वा छापको निर्माण वा परिवर्तन समावेश हुन्छ। दुवै अपराधमा लामो कैद र ठूलो जरिवाना सहित कडा सजाय हुन्छ।',
      keywords: ['counterfeit', 'forgery', 'jalasaji', 'nakkali mudra', 'fraud', 'signature forgery'],
    ),

    LegalDocument(
      id: 'pub_off_005',
      titleEn: 'Unlawful Assembly and Rioting',
      titleNp: 'गैरकानूनी सभा र दङ्गा',
      category: 'Public Offenses Act',
      contentEn: 'An unlawful assembly consists of five or more persons gathered with the common intention of committing an offense or intimidating authorities. Rioting occurs when an unlawful assembly uses force or violence in furtherance of their common objective. Participants in an unlawful assembly may be punished with imprisonment. Rioting carries more severe penalties, especially when it results in property damage or personal injury. Police have the authority to disperse unlawful assemblies using reasonable force.',
      contentNp: 'गैरकानूनी सभामा अपराध गर्ने वा अधिकारीहरूलाई धम्की दिने साझा आशयले जम्मा भएका पाँच वा बढी व्यक्तिहरू हुन्छन्। दङ्गा तब हुन्छ जब गैरकानूनी सभाले आफ्नो साझा उद्देश्य पूरा गर्न बल वा हिंसा प्रयोग गर्दछ। गैरकानूनी सभामा सहभागीहरूलाई कैदको सजाय हुन सक्छ।',
      keywords: ['unlawful assembly', 'rioting', 'gang', 'danga', 'public violence', 'police dispersal'],
    ),

    LegalDocument(
      id: 'pub_off_006',
      titleEn: 'Gambling and Betting Offenses',
      titleNp: 'जुवा र सट्टा सम्बन्धी अपराध',
      category: 'Public Offenses Act',
      contentEn: 'Gambling and betting are regulated under the Public Offenses Act and the Gambling Act. Operating a gambling house, participating in gambling, or being found in a gambling establishment are punishable offenses. Authorized lotteries and certain forms of betting regulated by law are exempted. Police may raid suspected gambling establishments, seize gambling equipment, and arrest participants. Repeat offenders face enhanced penalties.',
      contentNp: 'जुवा र सट्टा सार्वजनिक अपराध ऐन र जुवा ऐन अन्तर्गत नियमन गरिन्छ। जुवा घर सञ्चालन गर्ने, जुवामा भाग लिने, वा जुवा प्रतिष्ठानमा फेला पर्नु दण्डनीय अपराध हो। अधिकृत लटरी र कानूनद्वारा नियमन गरिएका निश्चित प्रकारको सट्टा छुट दिइएको छ।',
      keywords: ['gambling', 'betting', 'juwa', 'satta', 'gambling house', 'lottery', 'police raid'],
    ),

    LegalDocument(
      id: 'pub_off_007',
      titleEn: 'Obscenity and Immoral Traffic',
      titleNp: 'अश्लीलता र अनैतिक कारोबार',
      category: 'Public Offenses Act',
      contentEn: 'The publication, display, or distribution of obscene materials is prohibited under Nepalese law. Immoral traffic includes prostitution, brothel keeping, and soliciting. The Human Trafficking and Transportation Act addresses the commercial sexual exploitation of women and children. Offenses related to obscenity in digital media are also covered under the Electronic Transactions Act. Authorities conduct regular operations to curb obscenity and immoral trafficking networks.',
      contentNp: 'अश्लील सामग्रीको प्रकाशन, प्रदर्शन वा वितरण नेपाली कानून अन्तर्गत निषेधित छ। अनैतिक कारोबारमा वेश्यावृत्ति, वेश्यालय सञ्चालन र ग्राहक खोज्ने कार्य समावेश हुन्छ। मानव बेचबिखन तथा ओसारपसार ऐनले महिला र बालबालिकाको व्यावसायिक यौन शोषणलाई सम्बोधन गर्दछ।',
      keywords: ['obscenity', 'immoral traffic', 'prostitution', 'ashlilta', 'anaetik karobar', 'brothel'],
    ),

    LegalDocument(
      id: 'pub_off_008',
      titleEn: 'Weapons and Explosives Offenses',
      titleNp: 'हतियार र विस्फोटक पदार्थ सम्बन्धी अपराध',
      category: 'Public Offenses Act',
      contentEn: 'The Arms and Ammunition Act regulates the possession, sale, and use of firearms and weapons in Nepal. Unauthorized possession of firearms, explosives, or lethal weapons is a criminal offense. Licenses are required for the lawful possession of firearms, issued by the District Administration Office. The use of illegal weapons in the commission of other offenses attracts enhanced penalties. Import and export of weapons without authorization is strictly prohibited.',
      contentNp: 'हतियार तथा खरानी ऐनले नेपालमा बन्दुक र हतियारको कब्जा, बिक्री र प्रयोगलाई नियमन गर्दछ। बन्दुक, विस्फोटक पदार्थ वा घातक हतियारको अनधिकृत कब्जा फौजदारी अपराध हो। बन्दुकको कानूनी कब्जाको लागि जिल्ला प्रशासन कार्यालयद्वारा जारी इजाजतपत्र आवश्यक हुन्छ।',
      keywords: ['weapons', 'explosives', 'firearms', 'hatiyar', 'license', 'arms act', 'ammunition'],
    ),

    LegalDocument(
      id: 'elec_001',
      titleEn: 'Election Commission Powers and Functions',
      titleNp: 'निर्वाचन आयोगको अधिकार र कार्यहरू',
      category: 'Election Act',
      contentEn: 'The Election Commission of Nepal is a constitutional body responsible for conducting, supervising, and controlling elections for federal, provincial, and local levels. The Commission has the power to delimit constituencies, prepare voter lists, register political parties, and enforce election codes of conduct. It ensures that elections are held in a free, fair, and credible manner. The Commission also adjudicates election-related disputes and can postpone elections in emergency situations.',
      contentNp: 'नेपालको निर्वाचन आयोग संघीय, प्रदेश र स्थानीय तहको निर्वाचन सञ्चालन, पर्यवेक्षण र नियन्त्रणको लागि जिम्मेवार संवैधानिक निकाय हो। आयोगलाई निर्वाचन क्षेत्र निर्धारण, मतदाता सूची तयार, राजनीतिक दल दर्ता र निर्वाचन आचारसंहिता लागू गर्ने अधिकार छ।',
      keywords: ['election commission', 'voter list', 'constituency', 'nirwachan ayog', 'election code', 'political parties'],
    ),

    LegalDocument(
      id: 'elec_002',
      titleEn: 'Voter Registration and Eligibility',
      titleNp: 'मतदाता दर्ता र योग्यता',
      category: 'Election Act',
      contentEn: 'Every Nepali citizen who has attained the age of eighteen years is eligible to be registered as a voter. Voter registration is conducted by the Election Commission through designated registration centers across the country. Voters must register in their place of residence. The voter list is updated annually and published for public scrutiny. Citizens may file claims and objections regarding the voter list within a specified timeframe.',
      contentNp: 'अठार वर्ष उमेर पुगेको प्रत्येक नेपाली नागरिक मतदाताको रूपमा दर्ता हुन योग्य हुन्छ। मतदाता दर्ता निर्वाचन आयोगले देशभरका निर्दिष्ट दर्ता केन्द्रमार्फत सञ्चालन गर्दछ। मतदाताहरू आफ्नो बसोबासको स्थानमा दर्ता हुनुपर्दछ। मतदाता सूची वार्षिक रूपमा अद्यावधिक गरिन्छ र सार्वजनिक निरीक्षणको लागि प्रकाशित गरिन्छ।',
      keywords: ['voter registration', 'voter eligibility', 'voter list', 'matadata darta', 'age requirement', 'residence'],
    ),

    LegalDocument(
      id: 'elec_003',
      titleEn: 'Candidate Eligibility and Nomination',
      titleNp: 'उम्मेदवारको योग्यता र मनोनयन',
      category: 'Election Act',
      contentEn: 'Candidates for election must meet eligibility criteria including being a registered voter, meeting minimum age requirements, and not being disqualified by law. Nomination papers must be filed with the Election Officer within the specified timeframe. Candidates must deposit an election fee, which is forfeited if they fail to secure a minimum percentage of votes. A candidate may withdraw their candidacy within the prescribed period. Disqualifications include bankruptcy, criminal conviction, and holding an office of profit.',
      contentNp: 'निर्वाचनको लागि उम्मेदवारहरूले दर्ता भएको मतदाता हुनुपर्ने, न्यूनतम उमेर आवश्यकता पूरा गर्नुपर्ने र कानूनद्वारा अयोग्य नभएको हुनुपर्ने जस्ता योग्यता मापदण्ड पूरा गर्नुपर्दछ। मनोनयन पत्र निर्वाचन अधिकृतलाई निर्दिष्ट समयसीमाभित्र दायर गर्नुपर्दछ।',
      keywords: ['candidate', 'nomination', 'election fee', 'ummheduar', 'manonayan', 'disqualification', 'withdrawal'],
    ),

    LegalDocument(
      id: 'elec_004',
      titleEn: 'Election Campaign and Code of Conduct',
      titleNp: 'निर्वाचन प्रचार र आचारसंहिता',
      category: 'Election Act',
      contentEn: 'Election campaigns are regulated by the Election Commission through a Code of Conduct. The code limits campaign expenditure, prohibits the use of public resources for campaigning, bans hate speech and character assassination, and ensures equal media access for all candidates. Campaigning must cease forty-eight hours before polling day. Violations of the code may result in warnings, fines, or disqualification of the candidate.',
      contentNp: 'निर्वाचन प्रचार निर्वाचन आयोगले आचारसंहितामार्फत नियमन गर्दछ। आचारसंहिताले प्रचार खर्च सीमित गर्दछ, प्रचारको लागि सार्वजनिक स्रोतको प्रयोग निषेध गर्दछ, घृणात्मक भाषण र चरित्र हत्यालाई प्रतिबन्ध गर्दछ, र सबै उम्मेदवारको लागि समान मिडिया पहुँच सुनिश्चित गर्दछ। मतदानको अघिल्लो दिन अड़तालीस घण्टा अगाडि प्रचार बन्द गर्नुपर्दछ।',
      keywords: ['election campaign', 'code of conduct', 'campaign expenditure', 'nirwachan prachar', 'aacharsanhita', 'hate speech', 'media access'],
    ),

    LegalDocument(
      id: 'elec_005',
      titleEn: 'Polling Procedures and Voting',
      titleNp: 'मतदान प्रक्रिया र मतदान',
      category: 'Election Act',
      contentEn: 'Voting is conducted through secret ballot at designated polling stations. Voters must present valid identification to vote. The Election Commission deploys election officials, security personnel, and observers to ensure orderly voting. Special arrangements are made for senior citizens, persons with disabilities, and pregnant women. Electronic voting machines may be used in certain elections. Voting hours are from 7 AM to 5 PM. Results are counted at the counting center.',
      contentNp: 'मतदान निर्दिष्ट मतदान केन्द्रमा गोप्य मतपत्रमार्फत सञ्चालन गरिन्छ। मतदाताले मतदान गर्न वैध परिचयपत्र पेश गर्नुपर्दछ। निर्वाचन आयोगले व्यवस्थित मतदान सुनिश्चित गर्न निर्वाचन अधिकारी, सुरक्षाकर्मी र पर्यवेक्षक परिचालन गर्दछ। ज्येष्ठ नागरिक, अपाङ्गता भएका व्यक्तिहरू र गर्भवती महिलाहरूको लागि विशेष व्यवस्था गरिन्छ।',
      keywords: ['polling', 'voting', 'secret ballot', 'matadan', 'polling station', 'voter ID', 'counting', 'election observer'],
    ),

    LegalDocument(
      id: 'elec_006',
      titleEn: 'Election Offenses and Penalties',
      titleNp: 'निर्वाचन अपराध र सजाय',
      category: 'Election Act',
      contentEn: 'Election offenses include voter impersonation, multiple voting, bribery, undue influence, and tampering with ballot boxes or voting machines. Intentionally disclosing the secrecy of the ballot is also an offense. Rigging elections through fraud or violence is a serious crime. Penalties range from fines to imprisonment for up to several years. Persons convicted of election offenses are disqualified from voting or standing for election for a specified period.',
      contentNp: 'निर्वाचन अपराधहरूमा मतदाता प्रतिरूपण, बहु मतदान, घूस, अनुचित प्रभाव र मतपेटिका वा मतदान मेसिनमा छेडछाड समावेश हुन्छ। जानीबुझी मतको गोपनीयता खुलासा गर्नु पनि अपराध हो। ठगी वा हिंसामार्फत निर्वाचनमा गडबडी गर्नु गम्भीर अपराध हो।',
      keywords: ['election offenses', 'voter fraud', 'bribery', 'ballot tampering', 'nirwachan apradh', 'election rigging', 'disqualification'],
    ),

    LegalDocument(
      id: 'elec_007',
      titleEn: 'Electoral Constituency Delimitation',
      titleNp: 'निर्वाचन क्षेत्र निर्धारण',
      category: 'Election Act',
      contentEn: 'The Election Commission is responsible for delimiting electoral constituencies for federal and provincial elections. Constituencies are delimited on the basis of population, geographical features, and administrative convenience. The delimitation process ensures that each constituency has approximately the same population size. Public input and consultation are sought during the delimitation process. The final delimitation order is published in the Nepal Gazette.',
      contentNp: 'निर्वाचन आयोग संघीय र प्रदेश निर्वाचनको लागि निर्वाचन क्षेत्र निर्धारण गर्न जिम्मेवार छ। निर्वाचन क्षेत्र जनसङ्ख्या, भौगोलिक विशेषता र प्रशासनिक सुविधाको आधारमा निर्धारण गरिन्छ। क्षेत्र निर्धारण प्रक्रियाले प्रत्येक निर्वाचन क्षेत्रमा लगभग समान जनसङ्ख्या सुनिश्चित गर्दछ।',
      keywords: ['constituency', 'delimitation', 'nirwachan khestra', 'population basis', 'election district', 'gazette'],
    ),

    LegalDocument(
      id: 'elec_008',
      titleEn: 'Local Election Procedures',
      titleNp: 'स्थानीय निर्वाचन प्रक्रिया',
      category: 'Election Act',
      contentEn: 'Local elections in Nepal are held every five years to elect mayors, deputy mayors, ward chairs, and ward members for municipalities and rural municipalities. The election process follows the same general framework as federal and provincial elections but is adapted for local conditions. The Local Government Operation Act and the Election Act together govern local elections. Voters elect candidates directly. Results are declared by the Election Officer at the local level.',
      contentNp: 'नेपालमा स्थानीय निर्वाचन प्रत्येक पाँच वर्षमा नगरपालिका र गाउँपालिकाको लागि मेयर, उपमेयर, वडाध्यक्ष र वडा सदस्यहरू निर्वाचित गर्न आयोजित हुन्छ। निर्वाचन प्रक्रियाले संघीय र प्रदेश निर्वाचनको जस्तै सामान्य ढाँचा पछ्याउँछ तर स्थानीय परिस्थितिअनुसार अनुकूलित हुन्छ।',
      keywords: ['local election', 'mayor', 'ward chair', 'sthaniya nirwachan', 'local government', 'election officer', 'direct election'],
    ),

    LegalDocument(
      id: 'police_001',
      titleEn: 'Nepal Police Organization and Structure',
      titleNp: 'नेपाल प्रहरीको सङ्गठन र संरचना',
      category: 'Police Act',
      contentEn: 'Nepal Police is the primary law enforcement agency responsible for maintaining public order, preventing crime, and enforcing laws. The organization is headed by the Inspector General of Police (IGP) and operates under the Ministry of Home Affairs. The police structure includes the Nepal Police Headquarters, provincial police offices, district police offices, and area police offices. Specialized units include the Metropolitan Police, Traffic Police, Cyber Bureau, and the Armed Police Force.',
      contentNp: 'नेपाल प्रहरी सार्वजनिक व्यवस्था कायम, अपराध रोकथाम र कानून कार्यान्वयनको लागि जिम्मेवार प्रमुख कानून प्रवर्तन निकाय हो। यस सङ्गठनको नेतृत्व प्रहरी महानिरीक्षकले गर्दछ र गृह मन्त्रालय अन्तर्गत सञ्चालित हुन्छ। प्रहरी संरचनामा नेपाल प्रहरी प्रधान कार्यालय, प्रदेश प्रहरी कार्यालय, जिल्ला प्रहरी कार्यालय र क्षेत्रीय प्रहरी कार्यालयहरू समावेश छन्।',
      keywords: ['nepal police', 'IGP', 'police structure', 'law enforcement', 'prahi', 'home ministry', 'armed police'],
    ),

    LegalDocument(
      id: 'police_002',
      titleEn: 'Police Powers of Arrest and Detention',
      titleNp: 'प्रहरीको पक्राउ र हिरासतको अधिकार',
      category: 'Police Act',
      contentEn: 'Police officers have the power to arrest persons without a warrant in case of flagrant offenses or upon reasonable suspicion of involvement in a cognizable offense. The arrested person must be informed of the grounds of arrest and produced before a judicial authority within twenty-four hours. Police may also conduct searches of persons, premises, and vehicles with a warrant or under certain circumstances without a warrant. Detention beyond twenty-four hours requires judicial authorization.',
      contentNp: 'प्रहरी अधिकारीहरूलाई रङ्गेहात अपराधको अवस्थामा वा संज्ञानयोग्य अपराधमा संलग्नताको उचित शङ्कामा वारण्टविना व्यक्तिलाई पक्राउ गर्ने अधिकार हुन्छ। पक्राउ गरिएको व्यक्तिलाई पक्राउको आधारबारे जानकारी दिनुपर्दछ र चौबीस घण्टाभित्र न्यायिक अधिकारीसमक्ष पेश गर्नुपर्दछ।',
      keywords: ['arrest', 'detention', 'warrant', 'pakrau', 'search', '24 hours', 'judicial authority'],
    ),

    LegalDocument(
      id: 'police_003',
      titleEn: 'Traffic Police and Road Safety',
      titleNp: 'ट्राफिक प्रहरी र सडक सुरक्षा',
      category: 'Police Act',
      contentEn: 'The Traffic Police is a specialized unit of Nepal Police responsible for traffic management and road safety. Traffic police officers enforce traffic rules, issue citations for violations, investigate accidents, and manage traffic flow. They have the authority to stop vehicles, check documents, conduct breathalyzer tests for drunk driving, and impound vehicles. Traffic violations include speeding, reckless driving, driving without a license, and running red lights. Penalties include fines, license suspension, and imprisonment.',
      contentNp: 'ट्राफिक प्रहरी नेपाल प्रहरीको एक विशेष एकाइ हो जो ट्राफिक व्यवस्थापन र सडक सुरक्षाको लागि जिम्मेवार छ। ट्राफिक प्रहरी अधिकारीहरूले ट्राफिक नियम लागू गर्दछन्, उल्लङ्घनको लागि जरिवाना जारी गर्दछन्, दुर्घटनाको अनुसन्धान गर्दछन् र ट्राफिक प्रवाह व्यवस्थापन गर्दछन्।',
      keywords: ['traffic police', 'road safety', 'traffic rules', 'traphik prahi', 'drunk driving', 'fine', 'license suspension'],
    ),

    LegalDocument(
      id: 'police_004',
      titleEn: 'Police Accountability and Complaints',
      titleNp: 'प्रहरी जवाफदेहिता र उजुरी',
      category: 'Police Act',
      contentEn: 'Citizens may file complaints against police officers for misconduct, abuse of authority, or failure to perform duties. Complaints can be filed with the concerned police office, the Police Headquarters, or the National Human Rights Commission. The Police Act provides for departmental action against erring officers including suspension, reduction in rank, or dismissal from service. The Office of the Police Inspector General handles serious complaints. Judicial remedies are also available through the courts.',
      contentNp: 'नागरिकहरूले प्रहरी अधिकारीविरुद्ध दुराचार, अधिकारको दुरुपयोग वा कर्तव्य पालन गर्न असफल भएकोमा उजुरी दिन सक्छन्। उजुरी सम्बन्धित प्रहरी कार्यालय, प्रहरी प्रधान कार्यालय वा राष्ट्रिय मानव अधिकार आयोगमा दिन सकिन्छ। प्रहरी ऐनले गल्ती गर्ने अधिकारीविरुद्ध विभागीय कारबाहीको व्यवस्था गर्दछ।',
      keywords: ['police accountability', 'complaint', 'police misconduct', 'prahi jiwaphdehita', 'ujuri', 'departmental action', 'NHRC'],
    ),

    LegalDocument(
      id: 'police_005',
      titleEn: 'Community Policing Programs',
      titleNp: 'सामुदायिक प्रहरी कार्यक्रम',
      category: 'Police Act',
      contentEn: 'Community policing is a strategy that emphasizes building partnerships between police and communities to address crime and safety issues. Nepal Police implements community policing programs at the local level through beat policing, community meetings, and school safety programs. Community members are encouraged to report suspicious activities and cooperate with police investigations. The approach aims to build trust, reduce fear of crime, and enhance the quality of life.',
      contentNp: 'सामुदायिक प्रहरी एक रणनीति हो जसले अपराध र सुरक्षा मुद्दाहरू समाधान गर्न प्रहरी र समुदायबीच साझेदारी निर्माणमा जोड दिन्छ। नेपाल प्रहरीले स्थानीय स्तरमा बीट प्रहरी, सामुदायिक बैठक र विद्यालय सुरक्षा कार्यक्रममार्फत सामुदायिक प्रहरी कार्यक्रम कार्यान्वयन गर्दछ।',
      keywords: ['community policing', 'beat policing', 'neighborhood safety', 'samudayik prahi', 'police-community partnership', 'school safety'],
    ),

    LegalDocument(
      id: 'police_006',
      titleEn: 'Criminal Investigation Procedures',
      titleNp: 'आपराधिक अनुसन्धान प्रक्रिया',
      category: 'Police Act',
      contentEn: 'Police investigation of criminal offenses involves collecting evidence, interviewing witnesses, examining crime scenes, and identifying suspects. The investigation must be conducted in accordance with the Criminal Procedure Code. Police have the power to summon witnesses, seize evidence, and conduct forensic examinations. Investigation reports are submitted to the public prosecutor for review. The quality of police investigation is crucial for successful prosecution in court.',
      contentNp: 'फौजदारी अपराधको प्रहरी अनुसन्धानमा प्रमाण सङ्कलन, साक्षीहरूको अन्तर्वार्ता, घटनास्थल परीक्षण र संदिग्धहरूको पहिचान समावेश हुन्छ। अनुसन्धान फौजदारी कार्यविधि संहिताअनुसार सञ्चालन गरिनुपर्दछ। प्रहरीलाई साक्षीहरू बोलाउने, प्रमाण जफत गर्ने र फोरेन्सिक परीक्षण गर्ने अधिकार हुन्छ।',
      keywords: ['criminal investigation', 'evidence', 'crime scene', 'anusandhan', 'forensics', 'witness', 'prosecution'],
    ),

    LegalDocument(
      id: 'police_007',
      titleEn: 'Armed Police Force Duties',
      titleNp: 'सशस्त्र प्रहरी बलको कर्तव्य',
      category: 'Police Act',
      contentEn: 'The Armed Police Force (APF) is a specialized paramilitary force in Nepal responsible for maintaining internal security, counter-insurgency operations, border security, and VIP security. The APF also assists in disaster response and relief operations. The force is headed by an Inspector General and operates under the Ministry of Home Affairs. APF personnel receive specialized training in combat, crowd control, and crisis management.',
      contentNp: 'सशस्त्र प्रहरी बल नेपालको एक विशेष अर्धसैनिक बल हो जो आन्तरिक सुरक्षा, विद्रोहविरोधी अभियान, सीमा सुरक्षा र विशिष्ट व्यक्ति सुरक्षाको लागि जिम्मेवार छ। सशस्त्र प्रहरी बल विपद् प्रतिकार्य र उद्धार कार्यमा पनि सहायता गर्दछ। यस बलको नेतृत्व प्रहरी महानिरीक्षकले गर्दछ र गृह मन्त्रालय अन्तर्गत सञ्चालित हुन्छ।',
      keywords: ['armed police', 'APF', 'internal security', 'sashastra prahi', 'counter-insurgency', 'border security', 'disaster response'],
    ),

    LegalDocument(
      id: 'police_008',
      titleEn: 'Cyber Crime Investigation by Police',
      titleNp: 'प्रहरीद्वारा साइबर अपराध अनुसन्धान',
      category: 'Police Act',
      contentEn: 'The Nepal Police Cyber Bureau is the specialized unit for investigating cyber crimes including hacking, online fraud, identity theft, and social media offenses. The bureau uses advanced digital forensics tools to trace cyber criminals. It operates a 24-hour cyber crime hotline for public reporting. The bureau coordinates with international law enforcement agencies through INTERPOL for cross-border cyber crime cases. Public awareness programs on cyber safety are also conducted.',
      contentNp: 'नेपाल प्रहरी साइबर ब्युरो ह्याकिङ, अनलाइन ठगी, पहिचान चोरी र सामाजिक सञ्जल अपराध लगायत साइबर अपराधको अनुसन्धानको लागि विशेष एकाइ हो। ब्युरोले साइबर अपराधीहरू पत्ता लगाउन उन्नत डिजिटल फोरेन्सिक उपकरणहरू प्रयोग गर्दछ। सार्वजनिक रिपोर्टिङको लागि यसले चौबीस घण्टा साइबर अपराध हटलाइन सञ्चालन गर्दछ।',
      keywords: ['cyber bureau', 'cyber crime', 'digital forensics', 'saibar byuro', 'online fraud', 'hacking', 'INTERPOL', 'cyber safety'],
    ),

    LegalDocument(
      id: 'trans_001',
      titleEn: 'Vehicle Registration and Licensing',
      titleNp: 'सवारी दर्ता र इजाजतपत्र',
      category: 'Transport Management Act',
      contentEn: 'All motor vehicles in Nepal must be registered with the Department of Transport Management before being operated on public roads. The registration process involves vehicle inspection, payment of customs duties, and issuance of number plates. Registered vehicles receive a registration certificate and require periodic renewal. Transport licenses for commercial vehicles are issued based on route permits and fitness certificates. Driving licenses are issued after passing written and practical tests.',
      contentNp: 'नेपालका सबै मोटर सवारी साधनहरू सार्वजनिक सडकमा सञ्चालन गर्नुअघि यातायात व्यवस्थापन विभागमा दर्ता गरिनुपर्दछ। दर्ता प्रक्रियामा सवारी निरीक्षण, भन्सार शुल्क भुक्तानी र नम्बर प्लेट जारी समावेश हुन्छ। दर्ता भएका सवारी साधनहरूले दर्ता प्रमाणपत्र प्राप्त गर्दछन् र आवधिक नवीकरण आवश्यक हुन्छ।',
      keywords: ['vehicle registration', 'driving license', 'transport department', 'savari darta', 'number plate', 'route permit', 'fitness certificate'],
    ),

    LegalDocument(
      id: 'trans_002',
      titleEn: 'Traffic Rules and Regulations',
      titleNp: 'ट्राफिक नियम र विनियम',
      category: 'Transport Management Act',
      contentEn: 'The Traffic Rules and Regulations govern the conduct of drivers, pedestrians, and other road users. Key rules include obeying traffic signals, speed limits, lane discipline, wearing seatbelts, and using helmets for motorcyclists. The use of mobile phones while driving is prohibited. Overloading vehicles beyond prescribed limits is an offense. Driving under the influence of alcohol or drugs is strictly prohibited and punishable with fines, license suspension, and imprisonment.',
      contentNp: 'ट्राफिक नियम र विनियमहरूले चालक, पैदलयात्री र अन्य सडक प्रयोगकर्ताहरूको आचरण नियन्त्रण गर्दछ। मुख्य नियमहरूमा ट्राफिक संकेत पालना, गति सीमा, लेन अनुशासन, सीटबेल्ट प्रयोग र मोटरसाइकलको लागि हेलमेट प्रयोग समावेश छन्। सवारी चलाउँदा मोबाइल फोन प्रयोग निषेधित छ।',
      keywords: ['traffic rules', 'speed limit', 'seatbelt', 'helmet', 'traphik niyam', 'drunk driving', 'overloading', 'traffic signal'],
    ),

    LegalDocument(
      id: 'trans_003',
      titleEn: 'Public Transport Regulation',
      titleNp: 'सार्वजनिक यातायात नियमन',
      category: 'Transport Management Act',
      contentEn: 'Public transport services including buses, minibuses, taxis, and tempos are regulated by the Department of Transport Management. Operators must obtain route permits, fix fares according to government rates, and maintain vehicles in roadworthy condition. Public transport vehicles must display fare charts and route information. Passengers have the right to safe and comfortable travel. Overcharging, refusing passengers, and reckless driving by public transport drivers are punishable offenses.',
      contentNp: 'बस, मिनीबस, ट्याक्सी र टेम्पो लगायत सार्वजनिक यातायात सेवाहरू यातायात व्यवस्थापन विभागद्वारा नियमन गरिन्छ। सञ्चालकहरूले रुट अनुमति प्राप्त गर्नुपर्दछ, सरकारी दरअनुसार भाडा निर्धारण गर्नुपर्दछ र सवारी साधन सडक योग्य अवस्थामा राख्नुपर्दछ। सार्वजनिक यातायात सवारी साधनहरूले भाडा तालिका र रुट जानकारी प्रदर्शन गर्नुपर्दछ।',
      keywords: ['public transport', 'route permit', 'bus fare', 'sarbajanik yatayat', 'overcharging', 'passenger rights', 'roadworthy'],
    ),

    LegalDocument(
      id: 'trans_004',
      titleEn: 'Road Accident Investigation',
      titleNp: 'सडक दुर्घटना अनुसन्धान',
      category: 'Transport Management Act',
      contentEn: 'Road accidents are investigated by the Traffic Police to determine cause and responsibility. The investigation involves examining the accident scene, collecting physical evidence, interviewing witnesses, and reviewing vehicle conditions and driver records. Hit-and-run accidents carry enhanced penalties. Compensation for accident victims is available through motor insurance and the Victim Compensation Fund. Accident data is used for road safety planning.',
      contentNp: 'सडक दुर्घटनाको अनुसन्धान ट्राफिक प्रहरीले कारण र जिम्मेवारी निर्धारण गर्न गर्दछ। अनुसन्धानमा दुर्घटना स्थल परीक्षण, भौतिक प्रमाण सङ्कलन, साक्षीहरूको अन्तर्वार्ता र सवारी साधनको अवस्था तथा चालक अभिलेखको समीक्षा समावेश हुन्छ। हिट-एन्ड-रन दुर्घटनामा कडा सजाय हुन्छ।',
      keywords: ['road accident', 'traffic accident', 'hit and run', 'sadak durghatna', 'accident investigation', 'compensation', 'road safety'],
    ),

    LegalDocument(
      id: 'trans_005',
      titleEn: 'Vehicle Fitness and Pollution Control',
      titleNp: 'सवारी फिटनेस र प्रदूषण नियन्त्रण',
      category: 'Transport Management Act',
      contentEn: 'All motor vehicles must undergo periodic fitness tests to ensure they meet safety and environmental standards. The fitness test covers brakes, lights, tires, emissions, and overall vehicle condition. Vehicles that fail the test are prohibited from operating until repairs are made. Pollution control standards limit vehicle emissions. Vehicles exceeding emission limits are fined and required to install pollution control devices. The government promotes electric vehicles through tax incentives.',
      contentNp: 'सबै मोटर सवारी साधनहरूले सुरक्षा र वातावरणीय मापदण्ड पूरा गरेको सुनिश्चित गर्न आवधिक फिटनेस परीक्षण गराउनुपर्दछ। फिटनेस परीक्षणले ब्रेक, बत्ती, टायर, उत्सर्जन र समग्र सवारी अवस्था जाँच गर्दछ। परीक्षणमा असफल भएका सवारी साधनहरू मर्मत नभएसम्म सञ्चालन गर्न प्रतिबन्धित हुन्छन्।',
      keywords: ['vehicle fitness', 'pollution control', 'emission test', 'savari fitness', 'pradushan niyantran', 'electric vehicle', 'green tax'],
    ),

    LegalDocument(
      id: 'trans_006',
      titleEn: 'Transport Service Provider Licensing',
      titleNp: 'यातायात सेवा प्रदायक इजाजतपत्र',
      category: 'Transport Management Act',
      contentEn: 'Companies and individuals providing transport services must obtain licenses from the Department of Transport Management. Licensing requirements include proof of financial capacity, vehicle ownership, parking facilities, and compliance with labor laws. Transport service providers must maintain service standards, including punctuality, passenger safety, and complaint handling. Licenses may be suspended or revoked for violations. The act also regulates ride-sharing services and app-based transport.',
      contentNp: 'यातायात सेवा प्रदान गर्ने कम्पनी र व्यक्तिहरूले यातायात व्यवस्थापन विभागबाट इजाजतपत्र प्राप्त गर्नुपर्दछ। इजाजतपत्र आवश्यकताहरूमा वित्तीय क्षमता, सवारी स्वामित्व, पार्किङ सुविधा र श्रम कानूनको अनुपालनको प्रमाण समावेश हुन्छ। यातायात सेवा प्रदायकहरूले समयपालनता, यात्रु सुरक्षा र उजुरी व्यवस्थापन सहित सेवा मापदण्ड कायम गर्नुपर्दछ।',
      keywords: ['transport license', 'service provider', 'yatayat ijajatpatra', 'ride-sharing', 'app-based transport', 'service standard', 'complaint handling'],
    ),

    LegalDocument(
      id: 'trans_007',
      titleEn: 'International Transport and Transit',
      titleNp: 'अन्तर्राष्ट्रिय यातायात र पारवहन',
      category: 'Transport Management Act',
      contentEn: 'Nepal has bilateral agreements with neighboring countries for international transport and transit. The act regulates cross-border movement of goods and passenger vehicles. Customs clearance, transit permits, and compliance with international transport conventions are required. Vehicles entering Nepal must meet Nepalese safety and emission standards. Nepal is a member of regional transport agreements facilitating trade and movement within South Asia.',
      contentNp: 'नेपालसँग अन्तर्राष्ट्रिय यातायात र पारवहनको लागि छिमेकी देशहरूसँग द्विपक्षीय सम्झौताहरू छन्। ऐनले सीमापार वस्तु र यात्रु सवारी साधनको आवागमन नियमन गर्दछ। भन्सार क्लियरेन्स, पारवहन अनुमति र अन्तर्राष्ट्रिय यातायात सम्मेलनको अनुपालन आवश्यक हुन्छ।',
      keywords: ['international transport', 'transit', 'cross-border', 'antarrashtriya yatayat', 'bilateral agreement', 'customs', 'transit permit', 'SAARC'],
    ),

    LegalDocument(
      id: 'trans_008',
      titleEn: 'Transport Infrastructure and Planning',
      titleNp: 'यातायात पूर्वाधार र योजना',
      category: 'Transport Management Act',
      contentEn: 'The development of transport infrastructure including roads, bridges, airports, and railways is governed by the Transport Management Act and related legislation. The Department of Roads and the Civil Aviation Authority are responsible for infrastructure planning and development. Transport master plans are prepared at national and provincial levels. The act also addresses land acquisition for transport infrastructure, environmental impact assessments, and public-private partnerships in transport projects.',
      contentNp: 'सडक, पुल, विमानस्थल र रेलमार्ग सहित यातायात पूर्वाधारको विकास यातायात व्यवस्थापन ऐन र सम्बन्धित कानूनद्वारा नियमन गरिन्छ। सडक विभाग र नागरिक उड्डयन प्राधिकरण पूर्वाधार योजना र विकासको लागि जिम्मेवार छन्। यातायात मास्टर योजनाहरू राष्ट्रिय र प्रदेश स्तरमा तयार गरिन्छ।',
      keywords: ['transport infrastructure', 'roads', 'bridges', 'yatayat purbadhar', 'master plan', 'public-private partnership', 'EIA', 'airport'],
    ),
LegalDocument(
      id: 'ins_001',
      titleEn: 'Insurance Contract and Policy Formation',
      titleNp: 'बीमा सम्झौता र नीति गठन',
      category: 'Insurance Act',
      contentEn: 'An insurance contract is a legally binding agreement between the insurer and the insured, where the insurer agrees to compensate the insured for specific losses in exchange for premium payments. The contract must be based on utmost good faith, requiring full disclosure of material facts by both parties. The insurance policy documents the terms, conditions, coverage limits, exclusions, and premium amount. Policy formation follows regulatory guidelines issued by the Nepal Insurance Authority.',
      contentNp: 'बीमा सम्झौता बीमक र बीमितबीचको कानूनी रूपमा बाध्यकारी करार हो, जहाँ बीमकले प्रिमियम भुक्तानीको बदलामा निर्दिष्ट हानिको लागि बीमितलाई क्षतिपूर्ति दिन सहमत हुन्छ। सम्झौता पूर्ण सद्भावनामा आधारित हुनुपर्दछ, जसमा दुवै पक्षले भौतिक तथ्यहरूको पूर्ण खुलासा आवश्यक हुन्छ।',
      keywords: ['insurance', 'policy', 'premium', 'bima', 'insurer', 'insured', 'utmost good faith', 'disclosure'],
    ),

    LegalDocument(
      id: 'ins_002',
      titleEn: 'Life Insurance Regulations',
      titleNp: 'जीवन बीमा नियमन',
      category: 'Insurance Act',
      contentEn: 'Life insurance provides financial protection to the beneficiaries of the insured upon the death of the insured or after a specified term. Types of life insurance include term insurance, whole life insurance, endowment plans, and annuity plans. The Nepal Insurance Authority regulates life insurance products, premium rates, and claim settlement procedures. Life insurance companies must maintain solvency margins and reinsurance arrangements to protect policyholders interests.',
      contentNp: 'जीवन बीमाले बीमितको मृत्यु पश्चात वा निर्दिष्ट अवधि पछि बीमितको लाभार्थीलाई आर्थिक सुरक्षा प्रदान गर्दछ। जीवन बीमाका प्रकारहरूमा अवधि बीमा, सम्पूर्ण जीवन बीमा, अन्तःपूँजी योजना र वार्षिकी योजना समावेश छन्। नेपाल बीमा प्राधिकरणले जीवन बीमा उत्पादन, प्रिमियम दर र दाबी निरुपण प्रक्रिया नियमन गर्दछ।',
      keywords: ['life insurance', 'term insurance', 'endowment', 'jiwan bima', 'beneficiary', 'solvency', 'reinsurance', 'claim'],
    ),

    LegalDocument(
      id: 'ins_003',
      titleEn: 'Non-Life Insurance Regulations',
      titleNp: 'नन-लाइफ बीमा नियमन',
      category: 'Insurance Act',
      contentEn: 'Non-life insurance includes insurance against fire, marine, motor vehicle, aviation, engineering, health, and miscellaneous accidents. Motor insurance is compulsory for all vehicles operating on public roads. Fire insurance covers losses from fire, lightning, and explosions. Marine insurance covers loss or damage to ships and cargo during transit. The Nepal Insurance Authority sets minimum coverage requirements and standard policy terms for non-life insurance products.',
      contentNp: 'नन-लाइफ बीमामा आगो, समुद्री, मोटर सवारी, उड्डयन, ईन्जिनियरिङ, स्वास्थ्य र विविध दुर्घटनाविरुद्धको बीमा समावेश हुन्छ। सार्वजनिक सडकमा सञ्चालित सबै सवारी साधनको लागि मोटर बीमा अनिवार्य छ। आगो बीमाले आगो, चट्याङ र विस्फोटबाट हुने हानि समेट्दछ।',
      keywords: ['non-life insurance', 'motor insurance', 'fire insurance', 'marine insurance', 'gair-jiwan bima', 'motor bima', 'compulsory insurance'],
    ),

    LegalDocument(
      id: 'ins_004',
      titleEn: 'Insurance Claim and Settlement Process',
      titleNp: 'बीमा दाबी र निरुपण प्रक्रिया',
      category: 'Insurance Act',
      contentEn: 'The claim process begins when the insured notifies the insurer of a loss. The insured must submit a claim form with supporting documents including proof of loss, police reports, and estimates of damage. The insurer investigates the claim and may appoint a surveyor or loss adjuster. Claims must be settled within a reasonable timeframe as specified by regulations. If the claim is denied, the insurer must provide written reasons. Disputes may be referred to the Insurance Committee or the courts.',
      contentNp: 'दाबी प्रक्रिया बीमितले बीमकलाई हानिको सूचना दिएपछि सुरु हुन्छ। बीमितले हानिको प्रमाण, प्रहरी रिपोर्ट र क्षति अनुमान सहित सहायक कागजातसहित दाबी फारम पेश गर्नुपर्दछ। बीमकले दाबीको अनुसन्धान गर्दछ र सर्वेक्षक वा हानि समायोजक नियुक्त गर्न सक्छ।',
      keywords: ['claim', 'settlement', 'surveyor', 'dabi', 'nirupan', 'loss adjuster', 'claim denial', 'insurance committee'],
    ),

    LegalDocument(
      id: 'ins_005',
      titleEn: 'Insurance Intermediaries and Brokers',
      titleNp: 'बीमा मध्यस्थ र दलाल',
      category: 'Insurance Act',
      contentEn: 'Insurance agents, brokers, and surveyors operate as intermediaries between insurers and the public. They must be licensed by the Nepal Insurance Authority. Agents represent insurance companies and sell policies on their behalf. Brokers work independently and advise clients on the best insurance coverage. Surveyors assess losses and recommend claim amounts. All intermediaries must follow a code of conduct, maintain professional standards, and are subject to regulatory oversight.',
      contentNp: 'बीमा एजेन्ट, दलाल र सर्वेक्षकहरू बीमक र सर्वसाधारणबीच मध्यस्थको रूपमा काम गर्दछन्। उनीहरू नेपाल बीमा प्राधिकरणबाट इजाजतपत्र प्राप्त गर्नुपर्दछ। एजेन्टहरूले बीमा कम्पनीहरूको प्रतिनिधित्व गर्दछन् र उनीहरूको तर्फबाट नीति बेच्दछन्। दलालहरू स्वतन्त्र रूपमा काम गर्दछन् र ग्राहकहरूलाई उत्तम बीमा कभरेजको सल्लाह दिन्छन्।',
      keywords: ['insurance agent', 'broker', 'surveyor', 'bima ajanat', 'dalal', 'license', 'code of conduct', 'regulatory oversight'],
    ),

    LegalDocument(
      id: 'ins_006',
      titleEn: 'Microinsurance Regulations',
      titleNp: 'लघु बीमा नियमन',
      category: 'Insurance Act',
      contentEn: 'Microinsurance provides affordable insurance coverage to low-income individuals and communities. The Nepal Insurance Authority has issued special regulations for microinsurance to promote financial inclusion. Microinsurance products have simplified documentation, lower premiums, and streamlined claim processes. Products include crop insurance, livestock insurance, health microinsurance, and accidental death coverage. Microinsurance can be distributed through cooperatives, microfinance institutions, and community-based organizations.',
      contentNp: 'लघु बीमाले कम आय भएका व्यक्ति र समुदायलाई किफायती बीमा कभरेज प्रदान गर्दछ। नेपाल बीमा प्राधिकरणले वित्तीय समावेशीकरण प्रवर्धन गर्न लघु बीमाको लागि विशेष नियमन जारी गरेको छ। लघु बीमा उत्पादनहरूमा सरलीकृत कागजात, कम प्रिमियम र सरलीकृत दाबी प्रक्रिया हुन्छ।',
      keywords: ['microinsurance', 'laghu bima', 'financial inclusion', 'crop insurance', 'livestock insurance', 'cooperative', 'microfinance'],
    ),

    LegalDocument(
      id: 'ins_007',
      titleEn: 'Reinsurance and Risk Management',
      titleNp: 'पुनर्बीमा र जोखिम व्यवस्थापन',
      category: 'Insurance Act',
      contentEn: 'Reinsurance is a mechanism where insurance companies transfer portions of their risk portfolios to reinsurers to reduce their exposure to large losses. The Nepal Insurance Authority requires insurers to maintain reinsurance arrangements with approved domestic and international reinsurers. Risk management practices include underwriting standards, investment diversification, and catastrophe risk modeling. Proper risk management ensures the financial stability of the insurance sector and protects policyholders.',
      contentNp: 'पुनर्बीमा एक संयन्त्र हो जहाँ बीमा कम्पनीहरूले ठूलो हानिको जोखिम कम गर्न आफ्नो जोखिम पोर्टफोलियोको अंश पुनर्बीमकलाई हस्तान्तरण गर्दछन्। नेपाल बीमा प्राधिकरणले बीमकहरूलाई स्वीकृत घरेलु र अन्तर्राष्ट्रिय पुनर्बीमकहरूसँग पुनर्बीमा व्यवस्था कायम राख्न आवश्यक गर्दछ।',
      keywords: ['reinsurance', 'risk management', 'punarbima', 'jokhim byavasthapan', 'underwriting', 'catastrophe risk', 'solvency'],
    ),

    LegalDocument(
      id: 'ins_008',
      titleEn: 'Insurance Regulatory Authority',
      titleNp: 'बीमा नियामक प्राधिकरण',
      category: 'Insurance Act',
      contentEn: 'The Nepal Insurance Authority is the regulatory body overseeing the insurance sector in Nepal. It is responsible for licensing insurers, intermediaries, and surveyors; approving insurance products and premium rates; monitoring solvency and financial health; protecting policyholder interests; and promoting market development. The Authority has the power to inspect insurers, impose penalties, and in extreme cases, take over management of troubled companies. The Insurance Act grants the Authority its powers and functions.',
      contentNp: 'नेपाल बीमा प्राधिकरण नेपालमा बीमा क्षेत्रको नियमन गर्ने नियामक निकाय हो। यो बीमक, मध्यस्थ र सर्वेक्षकहरूलाई इजाजतपत्र दिने; बीमा उत्पादन र प्रिमियम दर स्वीकृत गर्ने; शोधक्षमता र वित्तीय स्वास्थ्य अनुगमन गर्ने; बीमितको हित संरक्षण गर्ने; र बजार विकास प्रवर्धन गर्ने जिम्मेवार छ।',
      keywords: ['insurance authority', 'regulator', 'bima adhikaran', 'license', 'solvency monitoring', 'policyholder protection', 'market development'],
    ),

    LegalDocument(
      id: 'health_001',
      titleEn: 'Public Health Service Act',
      titleNp: 'सार्वजनिक स्वास्थ्य सेवा ऐन',
      category: 'Health Law',
      contentEn: 'The Public Health Service Act establishes the framework for the delivery of public health services in Nepal. It covers preventive, curative, and promotional health services. The act mandates free basic health services at government health facilities. It establishes health service standards, patient rights, and complaint mechanisms. The Ministry of Health and Population is responsible for implementing the act. The act also addresses health workforce planning, health infrastructure, and quality assurance in health service delivery.',
      contentNp: 'सार्वजनिक स्वास्थ्य सेवा ऐनले नेपालमा सार्वजनिक स्वास्थ्य सेवा प्रवाहको लागि ढाँचा स्थापित गर्दछ। यसले रोकथाम, उपचार र प्रवर्धनात्मक स्वास्थ्य सेवा समेट्दछ। ऐनले सरकारी स्वास्थ्य संस्थाहरूमा नि:शुल्क आधारभूत स्वास्थ्य सेवा अनिवार्य गरेको छ। यसले स्वास्थ्य सेवा मापदण्ड, बिरामी अधिकार र उजुरी संयन्त्र स्थापित गर्दछ।',
      keywords: ['public health', 'health service', 'free health', 'sarbajanik swasthya', 'patient rights', 'health facility', 'quality assurance'],
    ),

    LegalDocument(
      id: 'health_002',
      titleEn: 'Medical Council Regulation',
      titleNp: 'चिकित्सक परिषद नियमन',
      category: 'Health Law',
      contentEn: 'The Nepal Medical Council regulates the medical profession in Nepal. It is responsible for registering medical practitioners, accrediting medical education institutions, and maintaining professional standards. All doctors must be registered with the Council to practice medicine in Nepal. The Council also handles complaints against medical professionals and can impose disciplinary actions including suspension or revocation of licenses. Continuing medical education is mandatory for license renewal.',
      contentNp: 'नेपाल चिकित्सक परिषदले नेपालमा चिकित्सा पेशालाई नियमन गर्दछ। यो चिकित्सकहरूको दर्ता, चिकित्सा शिक्षा संस्थाहरूको मान्यता र व्यावसायिक मापदण्ड कायम राख्न जिम्मेवार छ। नेपालमा चिकित्सा पेशा गर्न सबै डाक्टरहरू परिषदमा दर्ता हुनुपर्दछ। परिषदले चिकित्सकविरुद्ध उजुरीहरू पनि हेर्दछ।',
      keywords: ['medical council', 'doctor registration', 'chikitsak parishad', 'medical license', 'professional standard', 'disciplinary action', 'CME'],
    ),

    LegalDocument(
      id: 'health_003',
      titleEn: 'Pharmaceutical Regulation',
      titleNp: 'औषधि नियमन',
      category: 'Health Law',
      contentEn: 'The Department of Drug Administration regulates the manufacture, import, sale, and distribution of pharmaceuticals in Nepal. All drugs must be registered and approved before they can be marketed. The act sets quality standards for pharmaceutical products, inspects manufacturing facilities, and monitors adverse drug reactions. Pharmacies must be licensed and staffed by qualified pharmacists. The sale of counterfeit and expired drugs is strictly prohibited with severe penalties.',
      contentNp: 'औषधि प्रशासन विभागले नेपालमा औषधिको उत्पादन, आयात, बिक्री र वितरणलाई नियमन गर्दछ। बजारमा बिक्री गर्नुअघि सबै औषधि दर्ता र स्वीकृत हुनुपर्दछ। ऐनले औषधि उत्पादनको गुणस्तर मापदण्ड सेट गर्दछ, उत्पादन सुविधाको निरीक्षण गर्दछ र प्रतिकूल औषधि प्रतिक्रियाको अनुगमन गर्दछ।',
      keywords: ['pharmaceutical', 'drug regulation', 'aushadhi', 'pharmacy license', 'drug registration', 'quality control', 'counterfeit drugs'],
    ),

    LegalDocument(
      id: 'health_004',
      titleEn: 'Hospital and Health Facility Standards',
      titleNp: 'अस्पताल र स्वास्थ्य संस्था मापदण्ड',
      category: 'Health Law',
      contentEn: 'Hospitals and health facilities must meet minimum standards for infrastructure, equipment, staffing, and patient care. The Ministry of Health sets classification criteria for different levels of health facilities. All health facilities must be registered and obtain operating licenses. Standards cover emergency services, infection control, waste management, patient records, and quality of care. Regular inspections are conducted to ensure compliance. Non-compliant facilities may face fines, suspension, or closure.',
      contentNp: 'अस्पताल र स्वास्थ्य संस्थाहरूले पूर्वाधार, उपकरण, कर्मचारी र बिरामी हेरचाहको लागि न्यूनतम मापदण्ड पूरा गर्नुपर्दछ। स्वास्थ्य मन्त्रालयले विभिन्न तहको स्वास्थ्य संस्थाको लागि वर्गीकरण मापदण्ड निर्धारण गर्दछ। सबै स्वास्थ्य संस्थाहरू दर्ता हुनुपर्दछ र सञ्चालन इजाजतपत्र प्राप्त गर्नुपर्दछ।',
      keywords: ['hospital', 'health facility', 'aspatal', 'swasthya sanstha', 'accreditation', 'operating license', 'quality standard', 'infection control'],
    ),

    LegalDocument(
      id: 'health_005',
      titleEn: 'Health Insurance and Social Security',
      titleNp: 'स्वास्थ्य बीमा र सामाजिक सुरक्षा',
      category: 'Health Law',
      contentEn: 'The Government of Nepal operates a national health insurance program to provide universal health coverage. The Health Insurance Board manages the program, which covers inpatient and outpatient services, medicines, and diagnostics. Premiums are subsidized for poor and vulnerable populations. Social security programs provide additional health benefits to senior citizens, persons with disabilities, and single women. The program aims to reduce out-of-pocket health expenditure and improve healthcare access.',
      contentNp: 'नेपाल सरकारले विश्वव्यापी स्वास्थ्य कभरेज प्रदान गर्न राष्ट्रिय स्वास्थ्य बीमा कार्यक्रम सञ्चालन गर्दछ। स्वास्थ्य बीमा बोर्डले कार्यक्रम व्यवस्थापन गर्दछ, जसले आन्तरिक र बाहिरी बिरामी सेवा, औषधि र निदान सेवा समेट्दछ। गरिब र कमजोर जनसङ्ख्याको लागि प्रिमियममा अनुदान दिइन्छ।',
      keywords: ['health insurance', 'social security', 'swasthya bima', 'samajik suraksha', 'universal coverage', 'subsidy', 'senior citizen', 'out-of-pocket'],
    ),

    LegalDocument(
      id: 'health_006',
      titleEn: 'Mental Health Protection',
      titleNp: 'मानसिक स्वास्थ्य संरक्षण',
      category: 'Health Law',
      contentEn: 'The Mental Health Act provides for the protection of rights of persons with mental illness, regulation of psychiatric treatment, and establishment of mental health services. It prohibits discrimination against persons with mental illness and ensures their right to treatment, confidentiality, and informed consent. The act regulates psychiatric hospitals, community-based mental health services, and involuntary admission procedures. It also addresses suicide prevention and mental health awareness.',
      contentNp: 'मानसिक स्वास्थ्य ऐनले मानसिक रोग भएका व्यक्तिहरूको अधिकार संरक्षण, मनोचिकित्सा उपचारको नियमन र मानसिक स्वास्थ्य सेवाको स्थापनाको व्यवस्था गर्दछ। यसले मानसिक रोग भएका व्यक्तिहरूविरुद्ध भेदभाव निषेध गर्दछ र उपचारको अधिकार, गोपनीयता र सूचित सहमति सुनिश्चित गर्दछ।',
      keywords: ['mental health', 'psychiatric', 'manasik swasthya', 'mental illness', 'psychiatric hospital', 'involuntary admission', 'discrimination', 'suicide prevention'],
    ),

    LegalDocument(
      id: 'health_007',
      titleEn: 'Traditional and Alternative Medicine',
      titleNp: 'परम्परागत र वैकल्पिक चिकित्सा',
      category: 'Health Law',
      contentEn: 'Nepal recognizes traditional medicine systems including Ayurveda, homeopathy, and naturopathy alongside allopathic medicine. The Ayurveda and Alternative Medicine Act regulates the practice, education, and licensing of traditional medicine practitioners. The Department of Ayurveda promotes research and development of traditional medicine. Ayurvedic hospitals and clinics provide treatment using herbal medicines, dietary therapy, and lifestyle modifications. Integration of traditional and modern medicine is encouraged.',
      contentNp: 'नेपालले एलोपैथिक चिकित्साको साथै आयुर्वेद, होमियोप्याथी र प्राकृतिक चिकित्सा लगायत परम्परागत चिकित्सा प्रणालीलाई मान्यता दिन्छ। आयुर्वेद तथा वैकल्पिक चिकित्सा ऐनले परम्परागत चिकित्सकहरूको अभ्यास, शिक्षा र इजाजतपत्रलाई नियमन गर्दछ। आयुर्वेद विभागले परम्परागत चिकित्साको अनुसन्धान र विकास प्रवर्धन गर्दछ।',
      keywords: ['ayurveda', 'alternative medicine', 'homeopathy', 'paramparagat chikitsa', 'natural medicine', 'herbal', 'vaidya', 'traditional medicine'],
    ),

    LegalDocument(
      id: 'health_008',
      titleEn: 'Epidemic and Disease Control',
      titleNp: 'महामारी र रोग नियन्त्रण',
      category: 'Health Law',
      contentEn: 'The Epidemic Disease Control Act gives the government powers to prevent and control outbreaks of infectious diseases. The government may declare an epidemic, impose quarantine measures, restrict movement, and order compulsory vaccination. Health authorities conduct surveillance, contact tracing, and public awareness campaigns during outbreaks. Non-compliance with epidemic control measures is a punishable offense. The act ensures that disease control measures respect human rights and are proportionate.',
      contentNp: 'महामारी रोग नियन्त्रण ऐनले सरकारलाई सङ्क्रामक रोगको प्रकोप रोकथाम र नियन्त्रण गर्न अधिकार दिन्छ। सरकारले महामारी घोषणा गर्न, क्वारेन्टिन उपाय लागू गर्न, आवागमन प्रतिबन्ध लगाउन र अनिवार्य खोपको आदेश दिन सक्छ। स्वास्थ्य अधिकारीहरूले प्रकोपको समयमा निगरानी, सम्पर्क पत्ता लगाउने र सार्वजनिक जागरूकता अभियान सञ्चालन गर्दछन्।',
      keywords: ['epidemic', 'disease control', 'quarantine', 'mahamari', 'infectious disease', 'vaccination', 'contact tracing', 'public health emergency'],
    ),

    LegalDocument(
      id: 'agri_001',
      titleEn: 'Land Use and Agriculture Policy',
      titleNp: 'भू-उपयोग र कृषि नीति',
      category: 'Agricultural Law',
      contentEn: 'The Land Use Act classifies land into agricultural, residential, commercial, industrial, and public use categories. Agricultural land must be used for farming and related activities. Conversion of agricultural land to non-agricultural use requires permission from the relevant authority. The act aims to protect fertile agricultural land from haphazard urbanization. The government provides subsidies and incentives for agricultural production and productivity enhancement.',
      contentNp: 'भू-उपयोग ऐनले जग्गालाई कृषि, आवासीय, व्यावसायिक, औद्योगिक र सार्वजनिक प्रयोग श्रेणीमा वर्गीकरण गर्दछ। कृषि जग्गा खेती र सम्बन्धित गतिविधिको लागि प्रयोग गर्नुपर्दछ। कृषि जग्गालाई गैर-कृषि प्रयोगमा रूपान्तरण गर्न सम्बन्धित निकायबाट अनुमति आवश्यक हुन्छ।',
      keywords: ['agriculture', 'land use', 'krisi', 'bhu-upayog', 'farmland', 'subsidy', 'land conversion', 'productivity'],
    ),

    LegalDocument(
      id: 'agri_002',
      titleEn: 'Seed and Plant Protection',
      titleNp: 'बीउ र बिरुवा संरक्षण',
      category: 'Agricultural Law',
      contentEn: 'The Seed Act regulates the quality of seeds used in agriculture. Only registered and certified seeds may be sold to farmers. The act establishes seed testing laboratories, certification procedures, and quality standards. Plant protection measures include pest control, disease management, and quarantine regulations for imported plants. The government maintains seed banks and promotes the use of climate-resilient and high-yielding varieties.',
      contentNp: 'बीउ ऐनले कृषिमा प्रयोग हुने बीउको गुणस्तर नियमन गर्दछ। किसानहरूलाई दर्ता र प्रमाणित बीउ मात्र बेच्न सकिन्छ। ऐनले बीउ परीक्षण प्रयोगशाला, प्रमाणीकरण प्रक्रिया र गुणस्तर मापदण्ड स्थापित गर्दछ। बिरुवा संरक्षण उपायहरूमा कीरा नियन्त्रण, रोग व्यवस्थापन र आयातित बिरुवाको लागि क्वारेन्टिन नियमन समावेश हुन्छ।',
      keywords: ['seed', 'plant protection', 'biu', 'biruwa sanrakshan', 'seed certification', 'pest control', 'quarantine', 'high-yield variety'],
    ),

    LegalDocument(
      id: 'agri_003',
      titleEn: 'Fertilizer and Pesticide Regulation',
      titleNp: 'मल र कीटनाशक नियमन',
      category: 'Agricultural Law',
      contentEn: 'The Fertilizer and Pesticide Act regulates the import, production, sale, and use of agricultural inputs. Only registered fertilizers and pesticides that meet quality standards may be sold. The act restricts the use of highly toxic pesticides and promotes integrated pest management and organic farming. Adulterated or substandard fertilizers are prohibited. Violations result in fines and license revocation. The government provides subsidies on chemical and organic fertilizers to support farmers.',
      contentNp: 'मल तथा कीटनाशक ऐनले कृषि सामग्रीको आयात, उत्पादन, बिक्री र प्रयोगलाई नियमन गर्दछ। गुणस्तर मापदण्ड पूरा गर्ने दर्ता भएका मल र कीटनाशक मात्र बेच्न सकिन्छ। ऐनले अत्यधिक विषालु कीटनाशकको प्रयोगलाई प्रतिबन्ध गर्दछ र एकीकृत कीरा व्यवस्थापन तथा जैविक खेती प्रवर्धन गर्दछ।',
      keywords: ['fertilizer', 'pesticide', 'mal', 'kitnashak', 'organic farming', 'subsidy', 'integrated pest management', 'quality standard'],
    ),

    LegalDocument(
      id: 'agri_004',
      titleEn: 'Agricultural Marketing and Trade',
      titleNp: 'कृषि बजारीकरण र व्यापार',
      category: 'Agricultural Law',
      contentEn: 'The Agricultural Marketing Act establishes mechanisms for the marketing and trade of agricultural produce. It regulates agricultural markets, market fees, and grading standards. Farmers have the right to sell their produce directly or through agricultural cooperatives and collection centers. The government establishes minimum support prices for key crops to protect farmers from price fluctuations. Cold storage facilities, transportation subsidies, and export promotion programs support agricultural trade.',
      contentNp: 'कृषि बजारीकरण ऐनले कृषि उपजको बजारीकरण र व्यापारको लागि संयन्त्र स्थापित गर्दछ। यसले कृषि बजार, बजार शुल्क र ग्रेडिङ मापदण्ड नियमन गर्दछ। किसानहरूलाई आफ्नो उपज प्रत्यक्ष रूपमा वा कृषि सहकारी तथा सङ्कलन केन्द्रमार्फत बेच्ने अधिकार हुन्छ।',
      keywords: ['agricultural marketing', 'market fee', 'krisi bajar', 'minimum support price', 'cold storage', 'agricultural cooperative', 'export'],
    ),

    LegalDocument(
      id: 'agri_005',
      titleEn: 'Livestock and Animal Health',
      titleNp: 'पशुपालन र पशु स्वास्थ्य',
      category: 'Agricultural Law',
      contentEn: 'The Livestock Act regulates animal husbandry, livestock production, and animal health in Nepal. It provides for disease prevention, veterinary services, and animal breeding programs. Livestock farmers must register their animals and follow animal health protocols. The act addresses animal diseases including foot-and-mouth disease, bird flu, and swine fever. Veterinary hospitals and clinics provide treatment and vaccination services. Animal feed quality and slaughterhouse operations are also regulated.',
      contentNp: 'पशुपालन ऐनले नेपालमा पशुपालन, पशु उत्पादन र पशु स्वास्थ्यलाई नियमन गर्दछ। यसले रोग रोकथाम, पशु चिकित्सा सेवा र पशु प्रजनन कार्यक्रमको व्यवस्था गर्दछ। पशुपालक किसानहरूले आफ्ना पशुहरू दर्ता गर्नुपर्दछ र पशु स्वास्थ्य प्रोटोकल पालना गर्नुपर्दछ।',
      keywords: ['livestock', 'animal health', 'pashupalan', 'pasu swasthya', 'veterinary', 'animal disease', 'vaccination', 'slaughterhouse'],
    ),

    LegalDocument(
      id: 'agri_006',
      titleEn: 'Irrigation and Water Management',
      titleNp: 'सिँचाइ र पानी व्यवस्थापन',
      category: 'Agricultural Law',
      contentEn: 'The Irrigation Act governs the development and management of irrigation systems in Nepal. It provides for the construction, operation, and maintenance of irrigation infrastructure including canals, reservoirs, and pumping stations. Water users associations are formed at the local level to manage irrigation distribution. The act promotes efficient water use through modern irrigation technologies including drip and sprinkler systems. Water allocation during scarcity follows established priorities.',
      contentNp: 'सिँचाइ ऐनले नेपालमा सिँचाइ प्रणालीको विकास र व्यवस्थापनलाई नियमन गर्दछ। यसले नहर, जलाशय र पम्पिङ स्टेशन सहित सिँचाइ पूर्वाधारको निर्माण, सञ्चालन र मर्मतको व्यवस्था गर्दछ। स्थानीय स्तरमा सिँचाइ वितरण व्यवस्थापन गर्न पानी उपभोक्ता समितिहरू गठन गरिन्छ।',
      keywords: ['irrigation', 'water management', 'sinchai', 'pani byavasthapan', 'canal', 'water users association', 'drip irrigation', 'water allocation'],
    ),

    LegalDocument(
      id: 'agri_007',
      titleEn: 'Agricultural Credit and Insurance',
      titleNp: 'कृषि ऋण र बीमा',
      category: 'Agricultural Law',
      contentEn: 'The government provides agricultural credit through banks and financial institutions at subsidized interest rates. The Agriculture Development Bank and other commercial banks offer crop loans, livestock loans, and equipment financing. Agricultural insurance protects farmers against crop failure due to natural disasters, pests, and diseases. The government subsidizes insurance premiums for small and marginal farmers. Loan repayment schedules are flexible based on harvest cycles.',
      contentNp: 'सरकारले सहुलियत ब्याजदरमा बैंक तथा वित्तीय संस्थामार्फत कृषि ऋण प्रदान गर्दछ। कृषि विकास बैंक र अन्य वाणिज्य बैंकहरूले बाली ऋण, पशु ऋण र उपकरण वित्तीयकरण प्रदान गर्दछन्। कृषि बीमाले प्राकृतिक प्रकोप, कीरा र रोगका कारण बाली नष्ट हुँदा किसानलाई संरक्षण प्रदान गर्दछ।',
      keywords: ['agricultural credit', 'crop loan', 'krisi rin', 'bali beema', 'interest subsidy', 'Agriculture Development Bank', 'loan', 'crop insurance'],
    ),

    LegalDocument(
      id: 'agri_008',
      titleEn: 'Food Security and Nutrition',
      titleNp: 'खाद्य सुरक्षा र पोषण',
      category: 'Agricultural Law',
      contentEn: 'The Food Security Act guarantees the right to food for all citizens. The government maintains strategic food reserves, implements food distribution programs, and provides emergency food assistance during disasters. Nutrition programs address malnutrition among women, children, and vulnerable groups. The act promotes sustainable agriculture, food fortification, and dietary diversification. Local food production and farmers markets are encouraged to improve access to nutritious food.',
      contentNp: 'खाद्य सुरक्षा ऐनले सबै नागरिकको लागि खाद्य अधिकारको ग्यारेन्टी गर्दछ। सरकारले रणनीतिक खाद्य भण्डार कायम राख्दछ, खाद्य वितरण कार्यक्रम कार्यान्वयन गर्दछ र प्रकोपको समयमा आपतकालीन खाद्य सहायता प्रदान गर्दछ। पोषण कार्यक्रमहरूले महिला, बालबालिका र कमजोर समूहहरूबीच कुपोषणलाई सम्बोधन गर्दछ।',
      keywords: ['food security', 'nutrition', 'khadya suraksha', 'poshan', 'food reserve', 'food distribution', 'malnutrition', 'food fortification'],
    ),

    LegalDocument(
      id: 'const_007',
      titleEn: 'Right to Education and Culture',
      titleNp: 'शिक्षा र संस्कृतिको हक',
      category: 'Constitution',
      contentEn: 'Every citizen has the right to access quality education at all levels. The state shall provide free and compulsory education to children up to the secondary level. Citizens have the right to participate in cultural life and preserve their language and heritage. Educational institutions shall promote national unity, social harmony, and respect for diverse cultures. The state shall establish educational and cultural institutions in rural and remote areas. Higher education shall be accessible based on merit and capacity.',
      contentNp: 'प्रत्येक नागरिकलाई सबै तहमा गुणस्तरीय शिक्षामा पहुँच पाउने हक छ। राज्यले माध्यमिक तहसम्म बालबालिकालाई नि:शुल्क र अनिवार्य शिक्षा प्रदान गर्नेछ। नागरिकहरूलाई सांस्कृतिक जीवनमा भाग लिने र आफ्नो भाषा तथा सम्पदा संरक्षण गर्ने अधिकार छ। शैक्षिक संस्थाहरूले राष्ट्रिय एकता, सामाजिक सद्भाव र विविध संस्कृतिको सम्मान प्रवर्धन गर्नेछन्।',
      keywords: ['education right', 'cultural right', 'free education', 'shiksha hak', 'sanskritik hak', 'secondary education', 'national unity', 'cultural diversity'],
    ),

    LegalDocument(
      id: 'const_008',
      titleEn: 'Right to Employment and Social Security',
      titleNp: 'रोजगार र सामाजिक सुरक्षाको हक',
      category: 'Constitution',
      contentEn: 'Every citizen has the right to work and pursue employment of their choice. The state shall pursue policies to achieve full employment and ensure just and favorable working conditions. Citizens unable to work due to disability, old age, or other causes shall receive social security benefits. The state shall establish social security programs including health insurance, old age allowance, and disability benefits. Workers have the right to form trade unions and engage in collective bargaining.',
      contentNp: 'प्रत्येक नागरिकलाई काम गर्ने र आफूले रोजेको रोजगारी गर्ने हक छ। राज्यले पूर्ण रोजगारी प्राप्त गर्न र न्यायपूर्ण तथा अनुकूल कार्यस्थलको सुनिश्चितता गर्न नीति अवलम्बन गर्नेछ। अपाङ्गता, वृद्धावस्था वा अन्य कारणले काम गर्न नसक्ने नागरिकहरूले सामाजिक सुरक्षा लाभ प्राप्त गर्नेछन्।',
      keywords: ['employment right', 'social security', 'rojagar hak', 'samajik suraksha', 'full employment', 'trade union', 'old age allowance', 'disability benefit'],
    ),

    LegalDocument(
      id: 'const_009',
      titleEn: 'Right to Clean Environment',
      titleNp: 'स्वच्छ वातावरणको हक',
      category: 'Constitution',
      contentEn: 'Every person has the right to live in a clean and healthy environment. The state shall pursue policies to protect, conserve, and enhance the environment. The right includes access to clean air, water, and sanitation facilities. Citizens may file public interest litigation to enforce environmental rights. The state shall create awareness about environmental conservation and sustainable development. Responsibilities include the protection of forests, wildlife, and natural heritage.',
      contentNp: 'प्रत्येक व्यक्तिलाई स्वच्छ र स्वस्थ वातावरणमा बाँच्ने हक छ। राज्यले वातावरणको संरक्षण, संरक्षण र अभिवृद्धिको लागि नीति अवलम्बन गर्नेछ। यस हकमा स्वच्छ हावा, पानी र सरसफाइ सुविधामा पहुँच समावेश छ। नागरिकहरूले वातावरणीय अधिकार कार्यान्वयन गर्न सार्वजनिक सरोकारको मुद्दा दायर गर्न सक्छन्।',
      keywords: ['environment right', 'clean environment', 'swachha vatavaran', 'public interest litigation', 'conservation', 'sustainable development', 'wildlife protection'],
    ),

    LegalDocument(
      id: 'civil_008',
      titleEn: 'Partnership and Joint Venture Law',
      titleNp: 'साझेदारी र संयुक्त उद्यम कानून',
      category: 'Civil Law',
      contentEn: 'A partnership is a business relationship between two or more persons who agree to share profits and losses. The Partnership Act governs the formation, operation, and dissolution of partnerships. Partnerships may be registered or unregistered, with registered partnerships enjoying certain legal benefits. Joint ventures are contractual arrangements where parties undertake a specific business project together. Each partner is jointly and severally liable for partnership debts. Partners owe fiduciary duties to each other including good faith and full disclosure.',
      contentNp: 'साझेदारी दुई वा दुईभन्दा बढी व्यक्तिहरूबीच नाफा र नोक्सान बाँड्न सहमत भएको व्यावसायिक सम्बन्ध हो। साझेदारी ऐनले साझेदारीको गठन, सञ्चालन र विघटनलाई नियमन गर्दछ। साझेदारी दर्ता वा अदर्ता हुन सक्छ, दर्ता भएको साझेदारीले निश्चित कानूनी लाभ प्राप्त गर्दछ।',
      keywords: ['partnership', 'joint venture', 'sajhedari', 'sanyukta udyam', 'partner liability', 'fiduciary duty', 'partnership registration', 'profit sharing'],
    ),

    LegalDocument(
      id: 'civil_009',
      titleEn: 'Arbitration and Alternative Dispute Resolution',
      titleNp: 'मध्यस्थता र वैकल्पिक विवाद समाधान',
      category: 'Civil Law',
      contentEn: 'Alternative dispute resolution mechanisms include arbitration, mediation, conciliation, and negotiation. The Arbitration Act provides for the settlement of disputes through arbitration without resorting to litigation. Arbitration agreements are binding, and arbitral awards are enforceable as court judgments. Mediation involves a neutral third party facilitating negotiation between disputing parties. Courts may refer pending cases to mediation. ADR mechanisms reduce court backlog and provide faster, more cost-effective resolution.',
      contentNp: 'वैकल्पिक विवाद समाधान संयन्त्रहरूमा मध्यस्थता, सुलह, मेलमिलाप र वार्ता समावेश छन्। मध्यस्थता ऐनले मुद्दा नचलाई मध्यस्थतामार्फत विवाद समाधानको व्यवस्था गर्दछ। मध्यस्थता सम्झौता बाध्यकारी हुन्छ र मध्यस्थ आदेश अदालतको फैसलाजस्तै लागू हुन्छ।',
      keywords: ['arbitration', 'mediation', 'conciliation', 'madhyasthata', 'sulah', 'ADR', 'arbitral award', 'dispute resolution'],
    ),

    LegalDocument(
      id: 'civil_010',
      titleEn: 'Registration of Documents and Deeds',
      titleNp: 'कागजात र लिखत दर्ता',
      category: 'Civil Law',
      contentEn: 'Certain documents and deeds must be registered with the appropriate government authority to be legally valid. The Registration of Documents Act requires registration of deeds relating to immovable property, marriage settlements, partnership deeds, and powers of attorney. Registered documents are admissible as primary evidence in court. The registration process involves verification of identity, payment of stamp duty and registration fees, and recording in the official register. Unregistered documents may still be admissible as secondary evidence.',
      contentNp: 'निश्चित कागजात र लिखतहरू कानूनी रूपमा वैध हुनको लागि उपयुक्त सरकारी निकायमा दर्ता गरिनुपर्दछ। कागजात दर्ता ऐनले स्थावर सम्पत्ति, विवाह बन्डोस्ती, साझेदारी लिखत र मुख्तियारनामासँग सम्बन्धित लिखतहरूको दर्ता आवश्यक गर्दछ। दर्ता गरिएका कागजातहरू अदालतमा प्राथमिक प्रमाणको रूपमा स्वीकार्य हुन्छन्।',
      keywords: ['document registration', 'deed', 'kagajat darta', 'stamp duty', 'registration fee', 'primary evidence', 'power of attorney', 'lilapat'],
    ),
LegalDocument(
      id: 'local_006',
      titleEn: 'Public Hearing and Citizen Participation',
      titleNp: 'सार्वजनिक सुनुवाइ र नागरिक सहभागिता',
      category: 'Local Governance',
      contentEn: 'Local governments must conduct public hearings on important matters including budget formulation, development planning, and service delivery. Citizens have the right to participate in local governance through public hearings, ward committees, and citizen charters. The Local Government Operation Act mandates citizen participation in planning and decision-making processes. Feedback mechanisms include suggestion boxes, help desks, and social audits. Citizen participation enhances transparency, accountability, and responsiveness of local governments.',
      contentNp: 'स्थानीय सरकारहरूले बजेट निर्माण, विकास योजना र सेवा प्रवाह लगायत महत्त्वपूर्ण विषयहरूमा सार्वजनिक सुनुवाइ गर्नुपर्दछ। नागरिकहरूलाई सार्वजनिक सुनुवाइ, वडा समिति र नागरिक वडापत्रमार्फत स्थानीय शासनमा भाग लिने अधिकार छ। स्थानीय सरकार सञ्चालन ऐनले योजना र निर्णय प्रक्रियामा नागरिक सहभागिता अनिवार्य गर्दछ।',
      keywords: ['public hearing', 'citizen participation', 'sarbajanik sunuvai', 'nagarik sahabhagita', 'social audit', 'citizen charter', 'ward committee'],
    ),

    LegalDocument(
      id: 'local_007',
      titleEn: 'Local Infrastructure Development',
      titleNp: 'स्थानीय पूर्वाधार विकास',
      category: 'Local Governance',
      contentEn: 'Local governments are responsible for the development and maintenance of local infrastructure including local roads, bridges, water supply systems, drainage, street lighting, and public buildings. Infrastructure projects are planned through the participatory planning process. Local governments may implement projects through contractors, user committees, or public-private partnerships. Quality standards and environmental safeguards must be observed in all infrastructure projects.',
      contentNp: 'स्थानीय सरकारहरू स्थानीय सडक, पुल, खानेपानी प्रणाली, निकास, सडक बत्ती र सार्वजनिक भवन लगायत स्थानीय पूर्वाधारको विकास र मर्मतको लागि जिम्मेवार छन्। पूर्वाधार परियोजनाहरू सहभागितामूलक योजना प्रक्रियामार्फत योजना गरिन्छ। स्थानीय सरकारहरूले ठेकेदार, उपभोक्ता समिति वा सार्वजनिक-निजी साझेदारीमार्फत परियोजना कार्यान्वयन गर्न सक्छन्।',
      keywords: ['infrastructure', 'local roads', 'water supply', 'purvadhar', 'user committee', 'public-private partnership', 'quality standard'],
    ),

    LegalDocument(
      id: 'local_008',
      titleEn: 'Local Disaster Management',
      titleNp: 'स्थानीय विपद् व्यवस्थापन',
      category: 'Local Governance',
      contentEn: 'Local governments are the first responders in disaster situations and play a key role in disaster risk reduction and management. They prepare local disaster management plans, conduct risk assessments, and establish early warning systems. During emergencies, local governments coordinate search and rescue, relief distribution, and temporary shelter management. They also lead post-disaster reconstruction and rehabilitation efforts. Local disaster management committees are formed at municipal and ward levels.',
      contentNp: 'स्थानीय सरकारहरू विपद् अवस्थामा पहिलो प्रतिकारक हुन् र विपद् जोखिम न्यूनीकरण र व्यवस्थापनमा मुख्य भूमिका खेल्दछन्। तिनीहरूले स्थानीय विपद् व्यवस्थापन योजना तयार गर्दछन्, जोखिम मूल्याङ्कन गर्दछन् र पूर्व चेतावनी प्रणाली स्थापित गर्दछन्। आपतकालीन अवस्थामा, स्थानीय सरकारहरूले खोज तथा उद्धार, राहत वितरण र अस्थायी आश्रय व्यवस्थापनको समन्वय गर्दछन्।',
      keywords: ['disaster management', 'bipad byavasthapan', 'emergency response', 'early warning', 'search and rescue', 'relief distribution', 'reconstruction'],
    ),

    LegalDocument(
      id: 'prop_006',
      titleEn: 'Mortgage and Lien on Property',
      titleNp: 'सम्पत्ति धितो र प्रतिभार',
      category: 'Property Law',
      contentEn: 'Mortgage is the transfer of an interest in immovable property as security for a loan or debt. The mortgagor retains possession of the property while the mortgagee holds the right to recover the debt from the property. Lien is the right of a creditor to retain possession of a debtor property until the debt is paid. The Transfer of Property Act governs mortgages and liens. Registration of mortgage deeds is required. Foreclosure procedures allow lenders to recover defaulted loans through property sale.',
      contentNp: 'धितो भनेको ऋणको सुरक्षाको रूपमा स्थावर सम्पत्तिमा हितको हस्तान्तरण हो। धितो राख्ने व्यक्तिले सम्पत्तिको कब्जा राख्दछ जबकि धितो राख्ने व्यक्तिलाई सम्पत्तिबाट ऋण असुल गर्ने अधिकार हुन्छ। सम्पत्ति हस्तान्तरण ऐनले धितो र प्रतिभारलाई नियमन गर्दछ। धितो लिखतको दर्ता आवश्यक हुन्छ।',
      keywords: ['mortgage', 'lien', 'dhito', 'pratibhar', 'foreclosure', 'loan security', 'property charge', 'debt recovery'],
    ),

    LegalDocument(
      id: 'prop_007',
      titleEn: 'Easement and Right of Way',
      titleNp: 'सुविधा र बाटो अधिकार',
      category: 'Property Law',
      contentEn: 'Easement is the right of a person to use the land of another for a specific purpose, such as a right of way or drainage. Easements may be created by agreement, prescription, necessity, or by operation of law. An easement is attached to the dominant land and runs with the land. The servient owner must not interfere with the reasonable exercise of the easement. Easements are recorded in the land records. Extinguishment of easements occurs by release, merger, or abandonment.',
      contentNp: 'सुविधा भनेको कुनै व्यक्तिको विशिष्ट उद्देश्यको लागि अर्कोको जग्गा प्रयोग गर्ने अधिकार हो, जस्तै बाटो अधिकार वा निकास। सुविधा सम्झौता, व्यवहार, आवश्यकता वा कानूनको सञ्चालनद्वारा सिर्जना गर्न सकिन्छ। सुविधा प्रभावित जग्गासँग संलग्न हुन्छ र त्यस जग्गासँगै हस्तान्तरण हुन्छ।',
      keywords: ['easement', 'right of way', 'suvidha', 'bato adhikar', 'servient land', 'dominant land', 'drainage', 'land record'],
    ),

    LegalDocument(
      id: 'prop_008',
      titleEn: 'Adverse Possession of Land',
      titleNp: 'जग्गाको प्रतिकूल कब्जा',
      category: 'Property Law',
      contentEn: 'Adverse possession is a doctrine that allows a person to acquire legal title to land through continuous, open, and hostile possession for a statutory period. In Nepal, the limitation period for acquiring title by adverse possession is twelve years. The possession must be actual, exclusive, continuous, and hostile. The adverse possessor must pay land revenue during the possession period. Successful adverse possession claimants may apply for title registration.',
      contentNp: 'प्रतिकूल कब्जा एक सिद्धान्त हो जसले व्यक्तिलाई वैधानिक अवधिको लागि निरन्तर, खुला र प्रतिकूल कब्जामार्फत जग्गामा कानूनी स्वामित्व प्राप्त गर्न अनुमति दिन्छ। नेपालमा, प्रतिकूल कब्जाद्वारा स्वामित्व प्राप्त गर्ने सीमा अवधि बाह्र वर्ष हो। कब्जा वास्तविक, एकल, निरन्तर र प्रतिकूल हुनुपर्दछ।',
      keywords: ['adverse possession', 'pratikul kabja', 'title by possession', 'limitation', 'sima awadhi', 'land registration', 'possession period'],
    ),

    LegalDocument(
      id: 'public_006',
      titleEn: 'Civil Service and Government Employment',
      titleNp: 'निजामती सेवा र सरकारी रोजगार',
      category: 'Public Administration',
      contentEn: 'The Civil Service Act governs the recruitment, promotion, discipline, and conditions of service for civil servants in Nepal. The Public Service Commission conducts competitive examinations for permanent civil service positions. Civil servants are classified into gazetted and non-gazetted categories. Promotion is based on seniority, performance, and examinations. Disciplinary actions for misconduct include warnings, suspension, demotion, and dismissal. The Civil Service Code of Conduct requires impartiality, integrity, and dedication.',
      contentNp: 'निजामती सेवा ऐनले नेपालमा निजामती कर्मचारीहरूको भर्ती, पदोन्नति, अनुशासन र सेवाका सर्तहरू नियमन गर्दछ। लोक सेवा आयोगले स्थायी निजामती सेवा पदको लागि प्रतिस्पर्धात्मक परीक्षा सञ्चालन गर्दछ। निजामती कर्मचारीहरूलाई राजपत्राङ्कित र गैर-राजपत्राङ्कित श्रेणीमा वर्गीकृत गरिन्छ।',
      keywords: ['civil service', 'nijamati seva', 'Public Service Commission', 'recruitment', 'promotion', 'code of conduct', 'disciplinary action'],
    ),

    LegalDocument(
      id: 'public_007',
      titleEn: 'Right to Information and Transparency',
      titleNp: 'सूचनाको हक र पारदर्शिता',
      category: 'Public Administration',
      contentEn: 'The Right to Information Act gives citizens the right to access information held by public bodies. Citizens may request information by filing an application with the concerned public body. The public body must provide the requested information within fifteen days. Information officers are designated in each public body to facilitate access. Certain information may be withheld for reasons of national security, privacy, or confidentiality. The National Information Commission hears complaints and ensures compliance.',
      contentNp: 'सूचनाको हक ऐनले नागरिकहरूलाई सार्वजनिक निकायसँग रहेको सूचनामा पहुँच पाउने अधिकार दिन्छ। नागरिकहरूले सम्बन्धित सार्वजनिक निकायमा निवेदन दिएर सूचना माग्न सक्छन्। सार्वजनिक निकायले पन्ध्र दिनभित्र अनुरोधित सूचना प्रदान गर्नुपर्दछ। प्रत्येक सार्वजनिक निकायमा सूचना अधिकारी नियुक्त गरिन्छ।',
      keywords: ['right to information', 'soochana ko hak', 'transparency', 'pordarshita', 'National Information Commission', 'public body', 'information officer'],
    ),

    LegalDocument(
      id: 'public_008',
      titleEn: 'Administrative Tribunals and Review',
      titleNp: 'प्रशासनिक न्यायाधिकरण र पुनरावलोकन',
      category: 'Public Administration',
      contentEn: 'Administrative tribunals adjudicate disputes between citizens and government authorities. The Administrative Court hears cases related to civil service matters, government contracts, and administrative decisions. Citizens may appeal administrative decisions to higher authorities or the Administrative Court. Tribunals follow simplified procedures compared to regular courts. Judicial review of tribunal decisions is available through the Supreme Court. The principle of natural justice must be observed in all administrative proceedings.',
      contentNp: 'प्रशासनिक न्यायाधिकरणहरूले नागरिक र सरकारी निकायबीचको विवादको निरुपण गर्दछन्। प्रशासनिक अदालतले निजामती सेवा मामिला, सरकारी सम्झौता र प्रशासनिक निर्णयसँग सम्बन्धित मुद्दाहरू सुन्दछ। नागरिकहरूले प्रशासनिक निर्णयविरुद्ध माथिल्लो अधिकारी वा प्रशासनिक अदालतमा पुनरावेदन गर्न सक्छन्।',
      keywords: ['administrative tribunal', 'prashasanik nyayadikaran', 'administrative court', 'judicial review', 'natural justice', 'appeal', 'government decision'],
    ),

    LegalDocument(
      id: 'human_006',
      titleEn: 'Rights of Persons with Disabilities',
      titleNp: 'अपाङ्गता भएका व्यक्तिहरूको अधिकार',
      category: 'Human Rights',
      contentEn: 'The Rights of Persons with Disabilities Act ensures the rights and dignity of persons with disabilities. It prohibits discrimination on grounds of disability and mandates reasonable accommodation in public spaces, transportation, education, and employment. The act provides for accessible infrastructure, sign language interpretation, and assistive technology. Persons with disabilities have the right to participate in political, social, and cultural life. Disability identification cards enable access to benefits and services.',
      contentNp: 'अपाङ्गता भएका व्यक्तिहरूको अधिकार ऐनले अपाङ्गता भएका व्यक्तिहरूको अधिकार र मर्यादा सुनिश्चित गर्दछ। यसले अपाङ्गताको आधारमा भेदभाव निषेध गर्दछ र सार्वजनिक स्थल, यातायात, शिक्षा र रोजगारमा उचित सुविधा अनिवार्य गर्दछ। ऐनले पहुँचयोग्य पूर्वाधार, साङ्केतिक भाषा व्याख्या र सहायक प्रविधिको व्यवस्था गर्दछ।',
      keywords: ['disability rights', 'apangata', 'reasonable accommodation', 'accessible infrastructure', 'sign language', 'assistive technology', 'disability ID'],
    ),

    LegalDocument(
      id: 'human_007',
      titleEn: 'Rights of Women and Gender Equality',
      titleNp: 'महिला अधिकार र लैङ्गिक समानता',
      category: 'Human Rights',
      contentEn: 'The Constitution guarantees equal rights for women in all spheres of life. Specific legislation addresses gender-based violence, reproductive rights, workplace harassment, and property rights. Women have the right to equal pay for equal work, maternity protection, and representation in decision-making bodies. The government implements policies for women empowerment including education, health, and economic opportunities. Special provisions exist for Dalit women, rural women, and conflict-affected women.',
      contentNp: 'संविधानले जीवनका सबै क्षेत्रमा महिलाको लागि समान अधिकारको ग्यारेन्टी गर्दछ। विशिष्ट कानूनले लैङ्गिक हिंसा, प्रजनन अधिकार, कार्यस्थल उत्पीडन र सम्पत्ति अधिकारलाई सम्बोधन गर्दछ। महिलाहरूलाई समान कामको लागि समान ज्याला, मातृत्व संरक्षण र निर्णय प्रक्रियामा प्रतिनिधित्वको अधिकार छ।',
      keywords: ['women rights', 'mohila adhikar', 'gender equality', 'laingik samanta', 'gender-based violence', 'maternity protection', 'equal pay', 'reproductive rights'],
    ),

    LegalDocument(
      id: 'human_008',
      titleEn: 'Indigenous Peoples and Ethnic Rights',
      titleNp: 'आदिवासी जनजाति र जातीय अधिकार',
      category: 'Human Rights',
      contentEn: 'Indigenous peoples have the right to maintain and develop their distinct cultural identities, languages, traditions, and customary governance systems. The Constitution recognizes the rights of indigenous nationalities (Adivasi Janajati) and provides for their participation in state structures. The Indigenous Peoples Act protects their rights to land, resources, and traditional knowledge. The government has established the National Foundation for Development of Indigenous Nationalities.',
      contentNp: 'आदिवासी जनजातिहरूलाई आफ्नो विशिष्ट सांस्कृतिक पहिचान, भाषा, परम्परा र परम्परागत शासन प्रणाली कायम राख्ने र विकास गर्ने अधिकार छ। संविधानले आदिवासी जनजातिको अधिकार मान्यता दिन्छ र राज्य संरचनामा उनीहरूको सहभागिताको व्यवस्था गर्दछ। आदिवासी जनजाति ऐनले उनीहरूको भूमि, स्रोत र परम्परागत ज्ञानको अधिकार संरक्षण गर्दछ।',
      keywords: ['indigenous rights', 'adivasi janajati', 'ethnic rights', 'jatiya adhikar', 'traditional knowledge', 'cultural identity', 'customary governance', 'land rights'],
    ),

    LegalDocument(
      id: 'tech_005',
      titleEn: 'Data Protection and Privacy',
      titleNp: 'डाटा संरक्षण र गोपनीयता',
      category: 'Technology Law',
      contentEn: 'The protection of personal data and privacy is increasingly important in the digital age. Nepal is developing comprehensive data protection legislation to regulate the collection, processing, storage, and sharing of personal information. Data controllers must obtain consent before collecting personal data, ensure data security, and respect individuals rights to access, correct, and delete their data. Breaches of data protection requirements may result in penalties and liability for damages.',
      contentNp: 'डिजिटल युगमा व्यक्तिगत डाटा र गोपनीयताको संरक्षण बढ्दो रूपमा महत्त्वपूर्ण छ। नेपालले व्यक्तिगत जानकारीको सङ्कलन, प्रशोधन, भण्डारण र साझेदारीलाई नियमन गर्न व्यापक डाटा संरक्षण कानून विकास गरिरहेको छ। डाटा नियन्त्रकहरूले व्यक्तिगत डाटा सङ्कलन गर्नुअघि सहमति लिनुपर्दछ, डाटा सुरक्षा सुनिश्चित गर्नुपर्दछ।',
      keywords: ['data protection', 'privacy', 'data privacy', 'gopaniyata', 'personal data', 'consent', 'data breach', 'data security'],
    ),

    LegalDocument(
      id: 'tech_006',
      titleEn: 'Digital Payment and Financial Technology',
      titleNp: 'डिजिटल भुक्तानी र वित्तीय प्रविधि',
      category: 'Technology Law',
      contentEn: 'Digital payment systems including mobile banking, internet banking, digital wallets, and QR code payments are regulated by Nepal Rastra Bank. The Payment and Settlement Systems Act provides the legal framework for digital payments. Fintech companies must obtain licenses and comply with anti-money laundering requirements. Consumer protection measures include transaction limits, dispute resolution mechanisms, and data security standards. The government promotes cashless transactions through policy incentives.',
      contentNp: 'मोबाइल बैंकिङ, इन्टरनेट बैंकिङ, डिजिटल वालेट र क्यूआर कोड भुक्तानी सहित डिजिटल भुक्तानी प्रणाली नेपाल राष्ट्र बैंकद्वारा नियमन गरिन्छ। भुक्तानी तथा फर्छ्यौट प्रणाली ऐनले डिजिटल भुक्तानीको लागि कानूनी ढाँचा प्रदान गर्दछ। फिनटेक कम्पनीहरूले इजाजतपत्र प्राप्त गर्नुपर्दछ र मनी लान्ड्रिङ विरोधी आवश्यकता पालना गर्नुपर्दछ।',
      keywords: ['digital payment', 'fintech', 'mobile banking', 'digital bhuktani', 'QR payment', 'Nepal Rastra Bank', 'AML', 'payment system'],
    ),

    LegalDocument(
      id: 'tech_007',
      titleEn: 'Social Media Regulation',
      titleNp: 'सामाजिक सञ्जल नियमन',
      category: 'Technology Law',
      contentEn: 'The use of social media platforms is subject to Nepalese laws including the Electronic Transactions Act and the Criminal Code. The government may require social media companies to establish offices in Nepal, comply with content moderation rules, and provide user data upon lawful request. Hate speech, misinformation, and content that threatens public order may be removed. Social media companies must have grievance redressal mechanisms for users in Nepal.',
      contentNp: 'सामाजिक सञ्जल प्लेटफर्मको प्रयोग विद्युतीय कारोबार ऐन र फौजदारी संहिता लगायत नेपाली कानूनको अधीनमा छ। सरकारले सामाजिक सञ्जल कम्पनीहरूलाई नेपालमा कार्यालय स्थापना गर्न, सामग्री मध्यस्थता नियम पालना गर्न र कानूनी अनुरोधमा प्रयोगकर्ता डाटा प्रदान गर्न आवश्यक गर्न सक्छ।',
      keywords: ['social media', 'samajik sanjal', 'content moderation', 'hate speech', 'misinformation', 'grievance redressal', 'user data'],
    ),

    LegalDocument(
      id: 'tech_008',
      titleEn: 'E-Government and Digital Services',
      titleNp: 'ई-सरकार र डिजिटल सेवा',
      category: 'Technology Law',
      contentEn: 'The government promotes e-governance to improve service delivery through digital platforms. The Electronic Government Act provides the framework for online service delivery, digital signatures, and interoperability of government systems. Key initiatives include the online passport system, digital land records, e-tax filing, and the national identity card system. Citizens can access government services through service centers and mobile applications.',
      contentNp: 'सरकारले डिजिटल प्लेटफर्ममार्फत सेवा प्रवाह सुधार गर्न ई-शासन प्रवर्धन गर्दछ। विद्युतीय सरकार ऐनले अनलाइन सेवा प्रवाह, डिजिटल हस्ताक्षर र सरकारी प्रणालीको अन्तरसञ्चालनको लागि ढाँचा प्रदान गर्दछ। मुख्य पहलहरूमा अनलाइन राहदानी प्रणाली, डिजिटल जग्गा अभिलेख, ई-कर फाइलिङ र राष्ट्रिय परिचयपत्र प्रणाली समावेश छन्।',
      keywords: ['e-governance', 'digital service', 'e-sasn', 'online service', 'digital signature', 'national ID', 'e-tax', 'interoperability'],
    ),

    LegalDocument(
      id: 'env_005',
      titleEn: 'Climate Change and Adaptation',
      titleNp: 'जलवायु परिवर्तन र अनुकूलन',
      category: 'Environment Law',
      contentEn: 'Nepal is highly vulnerable to climate change impacts including glacial melting, floods, landslides, and changing weather patterns. The Climate Change Policy provides a framework for adaptation, mitigation, and climate-resilient development. The government has established the Climate Change Management Division to coordinate climate action. Key initiatives include renewable energy promotion, community-based adaptation programs, and early warning systems. Nepal participates in international climate agreements and accesses climate finance.',
      contentNp: 'नेपाल हिमाल पग्लने, बाढी, पहिरो र मौसम ढाँचामा परिवर्तन लगायत जलवायु परिवर्तनको प्रभावप्रति अत्यधिक संवेदनशील छ। जलवायु परिवर्तन नीतिले अनुकूलन, न्यूनीकरण र जलवायु-सहनशील विकासको लागि ढाँचा प्रदान गर्दछ। सरकारले जलवायु परिवर्तन समन्वय गर्न जलवायु परिवर्तन व्यवस्थापन महाशाखा स्थापना गरेको छ।',
      keywords: ['climate change', 'jalabayu parivartan', 'adaptation', 'mitigation', 'glacial melting', 'community-based adaptation', 'climate finance', 'renewable energy'],
    ),

    LegalDocument(
      id: 'env_006',
      titleEn: 'Forest Conservation and Management',
      titleNp: 'वन संरक्षण र व्यवस्थापन',
      category: 'Environment Law',
      contentEn: 'The Forest Act governs the conservation, management, and utilization of forests in Nepal. Community forestry is a successful model where local user groups manage forests for conservation and livelihood benefits. National parks, wildlife reserves, and conservation areas protect biodiversity. The act regulates timber harvesting, non-timber forest products collection, and forest clearance for development. Illegal logging and encroachment are punishable offenses. Nepal has achieved significant progress in increasing forest cover.',
      contentNp: 'वन ऐनले नेपालमा वनको संरक्षण, व्यवस्थापन र उपयोगलाई नियमन गर्दछ। सामुदायिक वन एक सफल मोडेल हो जहाँ स्थानीय उपभोक्ता समूहहरूले संरक्षण र जीविकोपार्जनको लागि वन व्यवस्थापन गर्दछन्। राष्ट्रिय निकुञ्ज, वन्यजन्तु आरक्ष र संरक्षण क्षेत्रहरूले जैविक विविधता संरक्षण गर्दछन्।',
      keywords: ['forest', 'ban', 'community forestry', 'samudayik ban', 'national park', 'wildlife', 'illegal logging', 'biodiversity'],
    ),

    LegalDocument(
      id: 'env_007',
      titleEn: 'Water Resources Management',
      titleNp: 'जलस्रोत व्यवस्थापन',
      category: 'Environment Law',
      contentEn: 'The Water Resources Act regulates the use, conservation, and management of water resources in Nepal. Water is a public trust and the state holds it in trust for the people. The act prioritizes water use for drinking, irrigation, hydropower, and industrial purposes. Water rights are granted through licensing. The act addresses water pollution, watershed management, and integrated water resource planning. Nepal has abundant water resources but faces challenges in equitable distribution and climate resilience.',
      contentNp: 'जलस्रोत ऐनले नेपालमा जलस्रोतको प्रयोग, संरक्षण र व्यवस्थापनलाई नियमन गर्दछ। पानी सार्वजनिक विश्वास हो र राज्यले यसलाई जनताको विश्वासमा राख्दछ। ऐनले खानेपानी, सिँचाइ, जलविद्युत र औद्योगिक प्रयोजनको लागि पानी प्रयोगलाई प्राथमिकता दिन्छ। जलस्रोत अधिकार इजाजतपत्रमार्फत प्रदान गरिन्छ।',
      keywords: ['water resources', 'jalsrot', 'hydropower', 'jalabidyut', 'water rights', 'watershed management', 'water pollution', 'water license'],
    ),

    LegalDocument(
      id: 'env_008',
      titleEn: 'Environmental Impact Assessment',
      titleNp: 'वातावरणीय प्रभाव मूल्याङ्कन',
      category: 'Environment Law',
      contentEn: 'Environmental Impact Assessment (EIA) is required for development projects that may have significant environmental impacts. The EIA process includes scoping, baseline study, impact prediction, mitigation planning, and public consultation. The Ministry of Forests and Environment reviews EIA reports and grants environmental approval. Initial Environmental Examination (IEE) is required for smaller projects. Projects must implement mitigation measures and monitoring plans. Public participation is an integral part of the EIA process.',
      contentNp: 'वातावरणीय प्रभाव मूल्याङ्कन महत्त्वपूर्ण वातावरणीय प्रभाव पार्न सक्ने विकास परियोजनाको लागि आवश्यक हुन्छ। वातावरणीय प्रभाव मूल्याङ्कन प्रक्रियामा परिदृश्य निर्धारण, आधारभूत अध्ययन, प्रभाव पूर्वानुमान, न्यूनीकरण योजना र सार्वजनिक परामर्श समावेश हुन्छ। वन तथा वातावरण मन्त्रालयले वातावरणीय प्रभाव मूल्याङ्कन प्रतिवेदन समीक्षा गर्दछ र वातावरणीय स्वीकृति प्रदान गर्दछ।',
      keywords: ['EIA', 'vatavarniya prabhab mulyankan', 'environmental impact', 'mitigation', 'IEE', 'public consultation', 'environmental approval', 'monitoring'],
    ),

    LegalDocument(
      id: 'edu_005',
      titleEn: 'University Governance and Regulation',
      titleNp: 'विश्वविद्यालय प्रशासन र नियमन',
      category: 'Education Law',
      contentEn: 'Universities in Nepal are established by federal or provincial acts and are governed by a Senate, Executive Council, and Academic Council. The University Grants Commission coordinates and allocates funding to universities and promotes quality assurance. Each university has autonomy in academic affairs, curriculum design, examination, and research. University laws regulate the appointment of Vice-Chancellors, faculty recruitment, student admissions, and degree conferral. Tribhuvan University, Kathmandu University, and Purbanchal University are major public universities.',
      contentNp: 'नेपालका विश्वविद्यालयहरू संघीय वा प्रदेश ऐनद्वारा स्थापित हुन्छन् र सिनेट, कार्य परिषद र शैक्षिक परिषदद्वारा सञ्चालित हुन्छन्। विश्वविद्यालय अनुदान आयोगले विश्वविद्यालयहरूलाई समन्वय र कोष विनियोजन गर्दछ र गुणस्तर आश्वासन प्रवर्धन गर्दछ। प्रत्येक विश्वविद्यालयलाई शैक्षिक मामिला, पाठ्यक्रम डिजाइन, परीक्षा र अनुसन्धानमा स्वायत्तता हुन्छ।',
      keywords: ['university', 'bishwabidyala', 'UGC', 'university grant', 'vice-chancellor', 'academic council', 'university autonomy', 'quality assurance'],
    ),

    LegalDocument(
      id: 'edu_006',
      titleEn: 'School Education and Management',
      titleNp: 'विद्यालय शिक्षा र व्यवस्थापन',
      category: 'Education Law',
      contentEn: 'Basic and secondary education in Nepal is delivered through community (public) and institutional (private) schools. The Education Act establishes the curriculum framework, examination system, and school management structure. School management committees govern community schools with parent and teacher representation. The government provides scholarships for underprivileged students. School leaving examinations are conducted by the National Examination Board. Minimum standards for school infrastructure and teacher qualifications are prescribed.',
      contentNp: 'नेपालमा आधारभूत र माध्यमिक शिक्षा सामुदायिक (सार्वजनिक) र संस्थागत (निजी) विद्यालयमार्फत प्रदान गरिन्छ। शिक्षा ऐनले पाठ्यक्रम ढाँचा, परीक्षा प्रणाली र विद्यालय व्यवस्थापन संरचना स्थापित गर्दछ। विद्यालय व्यवस्थापन समितिहरूले अभिभावक र शिक्षक प्रतिनिधित्वसहित सामुदायिक विद्यालयहरूको व्यवस्थापन गर्दछन्।',
      keywords: ['school education', 'vidyalaya shiksha', 'community school', 'samudayik vidyalaya', 'school management', 'SLC', 'National Examination Board', 'scholarship'],
    ),

    LegalDocument(
      id: 'edu_007',
      titleEn: 'Technical and Vocational Education',
      titleNp: 'प्राविधिक तथा व्यावसायिक शिक्षा',
      category: 'Education Law',
      contentEn: 'The Technical and Vocational Education and Training (TVET) system in Nepal provides skills training for employment. The Council for Technical Education and Vocational Training (CTEVT) regulates TVET institutions and curricula. Programs include diploma, certificate, and short-term skill training in fields like engineering, health sciences, agriculture, IT, and hospitality. Apprenticeship programs combine on-the-job training with classroom instruction. Government provides scholarships for TVET students from disadvantaged backgrounds.',
      contentNp: 'नेपालको प्राविधिक तथा व्यावसायिक शिक्षा तथा तालिम प्रणालीले रोजगारको लागि सीप तालिम प्रदान गर्दछ। प्राविधिक शिक्षा तथा व्यावसायिक तालिम परिषद्ले प्राविधिक तथा व्यावसायिक शिक्षा संस्था र पाठ्यक्रम नियमन गर्दछ। कार्यक्रमहरूमा ईन्जिनियरिङ, स्वास्थ्य विज्ञान, कृषि, सूचना प्रविधि र आतिथ्य जस्ता क्षेत्रमा डिप्लोमा, प्रमाणपत्र र अल्पकालीन सीप तालिम समावेश छन्।',
      keywords: ['TVET', 'CTEVT', 'technical education', 'prabidhik shiksha', 'vocational training', 'byawasayik talim', 'apprenticeship', 'skill training'],
    ),

    LegalDocument(
      id: 'edu_008',
      titleEn: 'Education Quality and Accreditation',
      titleNp: 'शिक्षा गुणस्तर र मान्यता',
      category: 'Education Law',
      contentEn: 'The Quality Assurance and Accreditation Council assesses and accredits higher education institutions based on standards of teaching, research, infrastructure, and governance. Accreditation is voluntary but incentivized through government funding and student preference. The council conducts institutional and program-level assessments. Institutions must meet minimum criteria for faculty qualifications, library resources, laboratory facilities, and student support services. Accreditation status is publicly available.',
      contentNp: 'गुणस्तर आश्वासन तथा मान्यता परिषद्ले शिक्षण, अनुसन्धान, पूर्वाधार र प्रशासनको मापदण्डको आधारमा उच्च शिक्षा संस्थाहरूको मूल्याङ्कन र मान्यता प्रदान गर्दछ। मान्यता स्वैच्छिक छ तर सरकारी कोष र विद्यार्थी प्राथमिकतामार्फत प्रोत्साहित गरिन्छ। परिषद्ले संस्थागत र कार्यक्रम-स्तरीय मूल्याङ्कन गर्दछ।',
      keywords: ['quality assurance', 'accreditation', 'gunastar aashwasan', 'manyata', 'QAAC', 'higher education', 'institutional assessment', 'program accreditation'],
    ),

    LegalDocument(
      id: 'corp_008',
      titleEn: 'Securities and Stock Exchange Regulation',
      titleNp: 'धितोपत्र र शेयर बजार नियमन',
      category: 'Corporate Law',
      contentEn: 'The Securities Board of Nepal regulates the securities market including the Nepal Stock Exchange. The board oversees public offerings, listing requirements, trading rules, and investor protection. Companies seeking to raise capital through public offerings must register a prospectus with the board. Insider trading, market manipulation, and fraud are prohibited. Listed companies must comply with disclosure requirements, corporate governance standards, and periodic financial reporting.',
      contentNp: 'नेपाल धितोपत्र बोर्डले नेपाल स्टक एक्सचेन्ज लगायत धितोपत्र बजारलाई नियमन गर्दछ। बोर्डले सार्वजनिक निर्गमन, सूचीकरण आवश्यकता, व्यापार नियम र लगानीकर्ता संरक्षणको पर्यवेक्षण गर्दछ। सार्वजनिक निर्गमनमार्फत पुँजी परिचालन गर्ने कम्पनीहरूले बोर्डमा विवरणपत्र दर्ता गर्नुपर्दछ।',
      keywords: ['securities', 'stock exchange', 'dhitopatar', 'share bajar', 'SEBON', 'public offering', 'insider trading', 'investor protection'],
    ),

    LegalDocument(
      id: 'corp_009',
      titleEn: 'Corporate Taxation and Compliance',
      titleNp: 'कर्पोरेट कर र अनुपालन',
      category: 'Corporate Law',
      contentEn: 'Companies in Nepal are subject to corporate income tax, value-added tax, and other applicable taxes. The Income Tax Act governs corporate taxation including tax rates, deductions, and filing requirements. Tax returns must be filed annually with the Inland Revenue Department. Transfer pricing rules apply to related-party transactions. Tax incentives are available for specific sectors including hydropower, tourism, and IT. Tax evasion is a criminal offense with penalties including fines and imprisonment.',
      contentNp: 'नेपालका कम्पनीहरू कर्पोरेट आयकर, मूल्य अभिवृद्धि कर र अन्य लागू हुने करको अधीनमा छन्। आयकर ऐनले कर दर, कटौती र फाइलिङ आवश्यकता लगायत कर्पोरेट करलाई नियमन गर्दछ। आन्तरिक राजस्व विभागमा वार्षिक रूपमा कर विवरण दायर गर्नुपर्दछ। सम्बन्धित पक्ष कारोबारमा स्थानान्तरण मूल्य नियम लागू हुन्छ।',
      keywords: ['corporate tax', 'korporate kar', 'income tax', 'ayakar', 'VAT', 'mulya abhibriddhi kar', 'Inland Revenue', 'tax compliance'],
    ),

    LegalDocument(
      id: 'corp_010',
      titleEn: 'Mergers, Acquisitions and Restructuring',
      titleNp: 'मर्जर, अधिग्रहण र पुनर्संरचना',
      category: 'Corporate Law',
      contentEn: 'Mergers and acquisitions are governed by the Company Act and approved by the Office of the Company Registrar. Mergers combine two or more companies into one, while acquisitions involve one company taking control of another. Shareholders must approve mergers through special resolutions. The Competition Act prevents anti-competitive mergers that create monopolies. Corporate restructuring includes demergers, spin-offs, and debt restructuring. Creditors rights are protected during restructuring.',
      contentNp: 'मर्जर र अधिग्रहण कम्पनी ऐनद्वारा नियमन गरिन्छ र कम्पनी रजिस्ट्रारको कार्यालयद्वारा स्वीकृत गरिन्छ। मर्जरले दुई वा बढी कम्पनीहरूलाई एउटामा मिलाउँदछ, जबकि अधिग्रहणमा एउटा कम्पनीले अर्कोको नियन्त्रण लिने कार्य समावेश हुन्छ। सेयरधनीहरूले विशेष प्रस्तावमार्फत मर्जर स्वीकृत गर्नुपर्दछ।',
      keywords: ['merger', 'acquisition', 'adhigrahan', 'company merger', 'corporate restructuring', 'punsarranchna', 'demerger', 'competition act'],
    ),
LegalDocument(
      id: 'crim_008',
      titleEn: 'Hate Speech and Incitement Offenses',
      titleNp: 'घृणात्मक अभिव्यक्ति र उक्साहट अपराध',
      category: 'Criminal Law',
      contentEn: 'Hate speech involves the incitement of hatred, discrimination, or violence against individuals or groups based on race, religion, ethnicity, gender, or other characteristics. Nepalese law prohibits hate speech and incitement to violence. The Criminal Code penalizes acts that promote enmity between different groups. Social media platforms have been directed to remove hate speech content. Victims of hate speech may file complaints with the police and seek legal remedies.',
      contentNp: 'घृणात्मक अभिव्यक्तिमा जाति, धर्म, जातजाति, लिङ्ग वा अन्य विशेषताको आधारमा व्यक्ति वा समूहविरुद्ध घृणा, भेदभाव वा हिंसा भड्काउने कार्य समावेश हुन्छ। नेपाली कानूनले घृणात्मक अभिव्यक्ति र हिंसाको उक्साहटलाई निषेध गर्दछ। फौजदारी संहिताले विभिन्न समूहबीच शत्रुता बढाउने कार्यलाई दण्डित गर्दछ।',
      keywords: ['hate speech', 'ghrina', 'incitement', 'uksahat', 'discrimination', 'bhedbhav', 'communal harmony', 'social media hate'],
    ),

    LegalDocument(
      id: 'crim_009',
      titleEn: 'White Collar Crimes and Fraud',
      titleNp: 'सेतो पोशाक अपराध र ठगी',
      category: 'Criminal Law',
      contentEn: 'White collar crimes include fraud, embezzlement, insider trading, tax evasion, and money laundering. These non-violent offenses are committed for financial gain by individuals, businesses, and government officials. Fraud involves intentional deception to secure unfair or unlawful gain. Money laundering is the process of concealing the origins of illegally obtained money. The Nepal Police Economic Crime Investigation Division investigates white collar crimes. Penalties include fines, asset forfeiture, and imprisonment.',
      contentNp: 'सेतो पोशाक अपराधहरूमा ठगी, गबन, भित्री कारोबार, कर छली र मनी लान्ड्रिङ समावेश छन्। यी अहिंसात्मक अपराधहरू व्यक्ति, व्यवसाय र सरकारी अधिकारीहरूले आर्थिक लाभको लागि गर्दछन्। ठगीमा अनुचित वा गैरकानूनी लाभ प्राप्त गर्न जानीबुझी धोका दिने कार्य समावेश हुन्छ।',
      keywords: ['white collar crime', 'fraud', 'thagi', 'money laundering', 'mani laundring', 'economic crime', 'tax evasion', 'asset forfeiture'],
    ),

    LegalDocument(
      id: 'crim_010',
      titleEn: 'Sexual Offenses and Protection',
      titleNp: 'यौन अपराध र संरक्षण',
      category: 'Criminal Law',
      contentEn: 'Sexual offenses under Nepalese law include rape, sexual assault, sexual harassment, and trafficking for sexual exploitation. The Criminal Code defines rape as sexual intercourse without consent, with enhanced penalties for rape of minors. Sexual harassment in the workplace is prohibited. Victims have the right to confidential medical examination, legal representation, and counseling. Special provisions for victim protection include in-camera proceedings and prohibition of victim identity disclosure.',
      contentNp: 'नेपाली कानून अन्तर्गत यौन अपराधहरूमा बलात्कार, यौन आक्रमण, यौन उत्पीडन र यौन शोषणको लागि बेचबिखन समावेश छन्। फौजदारी संहिताले बलात्कारलाई सहमतिविना यौन सम्पर्कको रूपमा परिभाषित गर्दछ, नाबालिगको बलात्कारको लागि कडा सजायको व्यवस्था गरेको छ। कार्यस्थलमा यौन उत्पीडन निषेधित छ।',
      keywords: ['sexual offense', 'rape', 'balkar', 'youn apradh', 'sexual harassment', 'youn utpidan', 'victim protection', 'in-camera'],
    ),

    LegalDocument(
      id: 'civ_proc_001',
      titleEn: 'Civil Court Jurisdiction and Hierarchy',
      titleNp: 'देवानी अदालतको अधिकारक्षेत्र र तहगत संरचना',
      category: 'Civil Law',
      contentEn: 'Nepalese civil courts are structured in a hierarchy: District Courts, High Courts, and the Supreme Court. District Courts have original jurisdiction over most civil matters within their territorial limits. High Courts hear appeals from District Courts and have limited original jurisdiction. The Supreme Court is the highest appellate court with the power of judicial review. Specialized courts include the Administrative Court, Revenue Tribunal, and Debt Recovery Tribunal.',
      contentNp: 'नेपालका देवानी अदालतहरू तहगत रूपमा संरचित छन्: जिल्ला अदालत, उच्च अदालत र सर्वोच्च अदालत। जिल्ला अदालतहरूलाई आफ्नो क्षेत्रीय सीमाभित्र अधिकांश देवानी मामिलामा मौलिक अधिकारक्षेत्र हुन्छ। उच्च अदालतहरूले जिल्ला अदालतको फैसलाविरुद्ध पुनरावेदन सुन्दछन् र सीमित मौलिक अधिकारक्षेत्र हुन्छ।',
      keywords: ['court hierarchy', 'adalat', 'District Court', 'jilla adalat', 'High Court', 'uchha adalat', 'Supreme Court', 'sarbochha adalat'],
    ),

    LegalDocument(
      id: 'civ_proc_002',
      titleEn: 'Limitation and Evidence Rules',
      titleNp: 'सीमा अवधि र प्रमाण नियम',
      category: 'Civil Law',
      contentEn: 'Evidence and limitation rules are crucial in civil litigation. The Evidence Act governs the admissibility, relevance, and weight of evidence in court. Primary evidence includes original documents and direct witness testimony. Secondary evidence permits copies and circumstantial evidence when primary evidence is unavailable. The burden of proof in civil cases rests on the plaintiff. Limitation periods vary by claim type and run from the date the cause of action accrues.',
      contentNp: 'देवानी मुद्दामा प्रमाण र सीमा अवधि नियमहरू महत्त्वपूर्ण हुन्छन्। प्रमाण ऐनले अदालतमा प्रमाणको स्वीकार्यता, सान्दर्भिकता र महत्त्वलाई नियमन गर्दछ। प्राथमिक प्रमाणमा मूल कागजात र प्रत्यक्ष साक्षी बयान समावेश हुन्छ। माध्यमिक प्रमाणले प्राथमिक प्रमाण उपलब्ध नभएको अवस्थामा प्रतिलिपि र परिस्थितिजन्य प्रमाणलाई अनुमति दिन्छ।',
      keywords: ['evidence', 'praman', 'burden of proof', 'praman ko bhar', 'admissibility', 'swikaryata', 'primary evidence', 'secondary evidence'],
    ),
  ];
}
