import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../features/rule_book/model/legal_document.dart';
import '../shared/services/nepal_law_api.dart';

const Map<String, String> _nepaliToRoman = {
  'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh',
  'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh',
  'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh',
  'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh',
  'न': 'n', 'प': 'p', 'फ': 'ph', 'ब': 'b',
  'भ': 'bh', 'म': 'm', 'य': 'y', 'र': 'r',
  'ल': 'l', 'व': 'v', 'श': 'sh', 'ष': 'sh',
  'स': 's', 'ह': 'h',
  'ा': 'a', 'ि': 'i', 'ी': 'i', 'ु': 'u', 'ू': 'u',
  'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au', 'ं': 'n',
  'अ': 'a', 'आ': 'aa', 'इ': 'i', 'ई': 'i',
  'उ': 'u', 'ऊ': 'u', 'ए': 'e', 'ओ': 'o',
};

String _transliterate(String input) {
  return input.split('').map((c) => _nepaliToRoman[c] ?? c).join();
}

bool _matchesQuery(String fieldValue, String queryLower, String queryTranslit) {
  if (queryLower.isEmpty) return true;
  final fLower = fieldValue.toLowerCase();
  final fTranslit = _transliterate(fLower);
  return fLower.contains(queryLower) ||
      fLower.contains(queryTranslit) ||
      fTranslit.contains(queryLower) ||
      fTranslit.contains(queryTranslit);
}

class LawState {
  final bool isLoading;
  final String? error;
  final List<LegalDocument> documents;
  final String searchQuery;
  final String? selectedCategory;
  final Set<String> bookmarkIds;

  const LawState({
    this.isLoading = false,
    this.error,
    this.documents = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.bookmarkIds = const {},
  });

  List<LegalDocument> get filteredDocuments {
    var result = documents;
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      final qTranslit = _transliterate(q);
      result = result.where((d) =>
        _matchesQuery(d.titleEn, q, qTranslit) ||
        _matchesQuery(d.titleNp, q, qTranslit) ||
        _matchesQuery(d.contentEn, q, qTranslit) ||
        _matchesQuery(d.contentNp, q, qTranslit) ||
        d.keywords.any((k) => _matchesQuery(k, q, qTranslit))
      ).toList();
    }
    if (selectedCategory != null) {
      result = result.where((d) => d.category == selectedCategory).toList();
    }
    return result;
  }

  List<String> get categories =>
    documents.map((d) => d.category).toSet().toList()..sort();

  LawState copyWith({
    bool? isLoading,
    String? error,
    List<LegalDocument>? documents,
    String? searchQuery,
    String? selectedCategory,
    Set<String>? bookmarkIds,
    bool clearError = false,
  }) {
    return LawState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      documents: documents ?? this.documents,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      bookmarkIds: bookmarkIds ?? this.bookmarkIds,
    );
  }
}

class LawNotifier extends StateNotifier<LawState> {
  Box<LegalDocument>? _docsBox;
  Box<String>? _metaBox;
  Box? _bookmarkBox;
  final Completer<void> _initCompleter = Completer();

  LawNotifier() : super(const LawState(isLoading: true)) {
    _init();
  }

  Future<void> get initDone => _initCompleter.future;

  Future<void> _init() async {
    try {
      _docsBox = await Hive.openBox<LegalDocument>('legal_docs');
      _metaBox = await Hive.openBox<String>('law_docs_meta');
      _bookmarkBox = await Hive.openBox('bookmarks');

      final bookmarkIds = _loadBookmarkIds();

      if (_docsBox!.isEmpty) {
        final seeds = _seedDocuments();
        final map = {for (final doc in seeds) doc.id: doc};
        await _docsBox!.putAll(map);
        await _metaBox!.put('seeded', 'true');
        state = LawState(
          documents: seeds,
          bookmarkIds: bookmarkIds,
        );
      } else {
        state = LawState(
          documents: _docsBox!.values.toList(),
          bookmarkIds: bookmarkIds,
        );
      }

      _initCompleter.complete();
      _backgroundFetch();
    } catch (e) {
      state = LawState(error: 'Failed to initialize: $e');
      _initCompleter.completeError(e);
    }
  }

  Set<String> _loadBookmarkIds() {
    if (_bookmarkBox == null) return {};
    final raw = _bookmarkBox!.get('ids');
    if (raw is List) {
      return raw.cast<String>().toSet();
    }
    return {};
  }

  Future<void> _saveBookmarkIds() async {
    await _bookmarkBox?.put('ids', state.bookmarkIds.toList());
  }

  Future<void> _backgroundFetch() async {
    try {
      final response = await NepalLawApi.fetchAll().timeout(
        const Duration(seconds: 10),
      );
      if (response.error == null && response.documents.isNotEmpty) {
        final docs = response.documents;
        final map = {for (final doc in docs) doc.id: doc};
        await _docsBox!.putAll(map);
        state = state.copyWith(
          documents: docs,
          error: null,
        );
        await _metaBox!.put('lastFetched', DateTime.now().toIso8601String());
      } else {
        state = state.copyWith(
          error: response.error,
          isLoading: false,
        );
      }
    } catch (_) {
      // silent failure
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> toggleBookmark(String docId) async {
    final ids = Set<String>.from(state.bookmarkIds);
    if (ids.contains(docId)) {
      ids.remove(docId);
    } else {
      ids.add(docId);
    }
    state = state.copyWith(bookmarkIds: ids);
    await _saveBookmarkIds();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await NepalLawApi.fetchAll().timeout(
        const Duration(seconds: 10),
      );
      if (response.error == null && response.documents.isNotEmpty) {
        final map = {for (final doc in response.documents) doc.id: doc};
        await _docsBox!.putAll(map);
        state = state.copyWith(
          documents: response.documents,
          isLoading: false,
        );
        await _metaBox!.put('lastFetched', DateTime.now().toIso8601String());
        await _metaBox!.put('isOffline', 'false');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'No documents found',
        );
        if (response.error != null) {
          await _metaBox!.put('isOffline', 'true');
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh: $e',
      );
      await _metaBox!.put('isOffline', 'true');
    }
  }
}

final lawStateProvider = StateNotifierProvider<LawNotifier, LawState>((ref) {
  return LawNotifier();
});

final lawProvider = FutureProvider<List<LegalDocument>>((ref) async {
  final notifier = ref.read(lawStateProvider.notifier);
  await notifier.initDone;
  return ref.read(lawStateProvider).documents;
});

final lawDocByIdProvider = FutureProvider.family<LegalDocument?, String>((ref, id) async {
  final docs = ref.read(lawStateProvider).documents;
  try {
    return docs.firstWhere((d) => d.id == id);
  } catch (_) {
    return null;
  }
});

List<LegalDocument> _seedDocuments() {
  return [
    LegalDocument(
      id: 'const_001',
      titleEn: 'Right to Fundamental Rights',
      titleNp: 'मौलिक हकको अधिकार',
      sectionNumber: 'Article 16-46',
      category: 'Constitution',
      contentEn: 'Every citizen shall have the right to enjoy fundamental rights guaranteed by the Constitution of Nepal. The fundamental rights include the right to equality, right to freedom, right against exploitation, right to religion, right to education and culture, right to health, right to justice, and right to constitutional remedies. No law shall be made that abridges or abrogates the fundamental rights conferred by this Constitution. The State shall not deny to any person equality before the law or equal protection of the laws within the territory of Nepal. All citizens shall be equal before the law. There shall be no discrimination on grounds of religion, race, caste, tribe, sex, origin, language, or ideological conviction. Special provisions may be made by law for the protection, empowerment, or advancement of women, Dalits, indigenous peoples, Madhesis, Tharus, Muslims, oppressed communities, persons with disabilities, and marginalized groups. The right to constitutional remedies enables any citizen to move the Supreme Court for the enforcement of fundamental rights through habeas corpus, mandamus, prohibition, quo warranto, and certiorari writs.',
      contentNp: 'प्रत्येक नागरिकले नेपालको संविधानद्वारा प्रत्याभूत मौलिक हकहरू उपभोग गर्ने अधिकार हुनेछ। मौलिक हकहरूमा समानताको हक, स्वतन्त्रताको हक, शोषणविरुद्धको हक, धार्मिक स्वतन्त्रताको हक, शिक्षा र संस्कृतिको हक, स्वास्थ्यको हक, न्यायको हक र संवैधानिक उपचारको हक समावेश छन्। यस संविधानद्वारा प्रदत्त मौलिक हकहरूको उल्लङ्घन वा खण्डन गर्ने कुनै पनि कानून बनाइने छैन। राज्यले नेपालको भू-भागभित्र कसैलाई पनि कानूनको अगाडि समानताको हक वा कानूनको समान संरक्षणबाट वञ्चित गर्ने छैन। सबै नागरिक कानूनको अगाडि समान हुनेछन्। धर्म, जाति, वर्ण, जातजाति, लिङ्ग, उत्पत्ति, भाषा वा वैचारिक आस्थाको आधारमा कुनै भेदभाव गरिने छैन। महिला, दलित, आदिवासी जनजाति, मधेसी, थारू, मुस्लिम, उत्पीडित समुदाय, अपाङ्गता भएका व्यक्तिहरू र सीमान्तकृत समूहहरूको संरक्षण, सशक्तीकरण वा उत्थानको लागि कानूनद्वारा विशेष व्यवस्था गर्न सकिनेछ। संवैधानिक उपचारको हकले कुनै पनि नागरिकलाई बन्दी प्रत्यक्षीकरण, परमादेश, निषेधाज्ञा, उत्प्रेषण र प्रमाणपत्र जारी गर्ने रिटमार्फत मौलिक हकको कार्यान्वयनको लागि सर्वोच्च अदालत जान सक्षम बनाउँदछ।',
      keywords: ['fundamental rights', 'equality', 'freedom', 'constitution', 'discrimination', 'maulik hak', 'samanta', 'constitutional remedies'],
    ),
    LegalDocument(
      id: 'const_002',
      titleEn: 'Structure of Federal Government',
      titleNp: 'संघीय सरकारको संरचना',
      sectionNumber: 'Article 55-59',
      category: 'Constitution',
      contentEn: 'The Constitution of Nepal establishes a federal democratic republican system with three levels of government: federal, provincial, and local. The federal government consists of the President, Vice-President, the Council of Ministers headed by the Prime Minister, and the Federal Parliament comprising the House of Representatives and the National Assembly. The executive power of Nepal shall be vested in the Council of Ministers. The President is the head of state and exercises ceremonial powers as specified by the Constitution. The Prime Minister is the head of government and exercises executive powers. The Federal Parliament shall have the power to make laws on matters enumerated in the Federal List, including defense, foreign affairs, national security, central banking, citizenship, interstate commerce, and international trade. The House of Representatives consists of 275 members elected through a mixed electoral system combining first-past-the-post and proportional representation. The National Assembly consists of 59 members, including at least three women, one Dalit, and one person with disability.',
      contentNp: 'नेपालको संविधानले संघ, प्रदेश र स्थानीय गरी तीन तहको सरकार भएको संघीय लोकतान्त्रिक गणतन्त्रात्मक प्रणाली स्थापना गरेको छ। संघीय सरकारमा राष्ट्रपति, उपराष्ट्रपति, प्रधानमन्त्रीको नेतृत्वमा रहने मन्त्रीपरिषद्, र प्रतिनिधिसभा र राष्ट्रियसभा मिलेर बनेको संघीय संसद् रहेको छ। नेपालको कार्यकारिणी शक्ति मन्त्रीपरिषद्मा निहित हुनेछ। राष्ट्रपति राज्यको प्रमुख हुनेछन् र संविधानले तोकेबमोजिमको औपचारिक अधिकार प्रयोग गर्नेछन्। प्रधानमन्त्री सरकारको प्रमुख हुनेछन् र कार्यकारी अधिकार प्रयोग गर्नेछन्। संघीय संसद्ले संघीय सूचीमा उल्लेखित विषयहरूमा कानून बनाउने अधिकार हुनेछ, जसमा रक्षा, परराष्ट्र मामिला, राष्ट्रिय सुरक्षा, केन्द्रीय बैंक, नागरिकता, अन्तरप्रदेश व्यापार र अन्तर्राष्ट्रिय व्यापार समावेश छन्। प्रतिनिधिसभामा प्रत्यक्ष निर्वाचन र समानुपातिक प्रतिनिधित्वको मिश्रित निर्वाचन प्रणालीमार्फत निर्वाचित २७५ सदस्य हुन्छन्। राष्ट्रियसभामा कम्तीमा तीन महिला, एक दलित र एक अपाङ्गता भएको व्यक्तिसहित ५९ सदस्य हुन्छन्।',
      keywords: ['federal government', 'president', 'prime minister', 'parliament', 'federal structure', 'sanghiya sarkar', 'constitution', 'council of ministers'],
    ),
    LegalDocument(
      id: 'const_003',
      titleEn: 'Citizenship Provisions',
      titleNp: 'नागरिकताको व्यवस्था',
      sectionNumber: 'Article 10-15',
      category: 'Constitution',
      contentEn: 'The Constitution of Nepal provides for the acquisition, termination, and re-acquisition of citizenship. Citizenship may be acquired by descent, by birth, or by naturalization. A person born to a Nepali citizen father and mother shall acquire citizenship by descent. A person born in Nepal to a Nepali mother and an unknown father, or to parents who are stateless, shall acquire citizenship by birth. Foreign women married to Nepali citizens may acquire naturalized citizenship as provided by federal law. The Government of Nepal may grant honorary citizenship to distinguished foreign nationals. Citizenship certificates shall be issued by the Government of Nepal. Citizens shall have the right to obtain a passport and other travel documents. No citizen shall be denied the right to enter, remain in, or leave Nepal except as provided by law. Dual citizenship is not permitted in Nepal, but provisions may be made for non-resident Nepali status for former citizens who have acquired foreign citizenship.',
      contentNp: 'नेपालको संविधानले नागरिकता प्राप्ति, समाप्ति र पुनः प्राप्तिको व्यवस्था गरेको छ। नागरिकता वंशजद्वारा, जन्मद्वारा वा प्राकृतिकीकरणद्वारा प्राप्त गर्न सकिन्छ। नेपाली नागरिक बाबु र आमाबाट जन्मेको व्यक्तिले वंशजको आधारमा नागरिकता प्राप्त गर्नेछ। नेपाली आमा र अज्ञात बाबु, वा राज्यविहीन आमाबाबुबाट नेपालमा जन्मेको व्यक्तिले जन्मको आधारमा नागरिकता प्राप्त गर्नेछ। नेपाली नागरिकसँग विवाह गरेकी विदेशी महिलाले संघीय कानूनले व्यवस्था गरेबमोजिम प्राकृतिकीकृत नागरिकता प्राप्त गर्न सक्नेछन्। नेपाल सरकारले विशिष्ट विदेशी नागरिकहरूलाई मानार्थ नागरिकता प्रदान गर्न सक्नेछ। नागरिकताको प्रमाणपत्र नेपाल सरकारले जारी गर्नेछ। नागरिकहरूलाई राहदानी र अन्य यात्रा कागजात प्राप्त गर्ने अधिकार हुनेछ। कानूनले व्यवस्था गरेको बाहेक कुनै पनि नागरिकलाई नेपाल प्रवेश गर्ने, बस्ने वा छोड्ने अधिकारबाट वञ्चित गरिने छैन। नेपालमा दोहोरो नागरिकताको अनुमति छैन, तर विदेशी नागरिकता प्राप्त गरेका पूर्व नागरिकहरूको लागि गैर-आवासीय नेपालीको स्थितिको व्यवस्था गर्न सकिनेछ।',
      keywords: ['citizenship', 'naturalization', 'passport', 'non-resident Nepali', 'nagarikata', 'descent', 'birth', 'honorary citizenship'],
    ),
    LegalDocument(
      id: 'civil_001',
      titleEn: 'Contract Formation and Validity',
      titleNp: 'सम्झौता गठन र वैधता',
      sectionNumber: 'Section 1-45',
      category: 'Civil Law',
      contentEn: 'A contract is an agreement between two or more parties that creates legally binding obligations. For a contract to be valid, it must contain an offer, acceptance of that offer, lawful consideration, and the intention to create legal relations. Both parties must have the capacity to contract, meaning they must be of the age of majority, of sound mind, and not disqualified by law. Consent must be free, not obtained through coercion, undue influence, fraud, misrepresentation, or mistake. The subject matter of the contract must be lawful and not contrary to public policy. A contract in writing is not always necessary, but certain contracts such as those relating to immovable property, marriage settlements, and agreements that cannot be performed within one year must be in writing and registered. If a contract is void, it has no legal effect from the beginning. A voidable contract remains valid until the party entitled to avoid it exercises that right.',
      contentNp: 'सम्झौता दुई वा दुईभन्दा बढी पक्षहरूबीचको सहमति हो जसले कानूनी रूपमा बाध्यकारी दायित्वहरू सिर्जना गर्दछ। सम्झौता वैध हुनको लागि यसमा प्रस्ताव, त्यस प्रस्तावको स्वीकृति, वैध प्रतिफल, र कानूनी सम्बन्ध सिर्जना गर्ने आशय हुनुपर्दछ। दुवै पक्षहरूमा सम्झौता गर्ने क्षमता हुनुपर्दछ, अर्थात् तिनीहरू वयस्क उमेरका, सचेत मनका, र कानूनद्वारा अयोग्य नभएका हुनुपर्दछ। सहमति स्वतन्त्र हुनुपर्दछ, जबरजस्ती, अनुचित प्रभाव, धोखाधडी, गलत बयान वा गल्तीबाट प्राप्त गरिएको हुनुहुँदैन। सम्झौताको विषय वस्तु कानूनी हुनुपर्दछ र सार्वजनिक नीतिको विपरीत हुनुहुँदैन। लिखित सम्झौता सधैं आवश्यक हुँदैन, तर स्थावर सम्पत्ति, विवाह बन्डोस्ती, र एक वर्षभित्र पूरा नहुने सम्झौताहरू लिखित र दर्ता हुनुपर्दछ। यदि सम्झौता शून्य छ भने, यसको सुरुदेखि नै कुनै कानूनी प्रभाव हुँदैन। शून्यकरणीय सम्झौता तबसम्म वैध रहन्छ जबसम्म यसलाई बेवास्ता गर्न हकदार पक्षले त्यो अधिकार प्रयोग गर्दैन।',
      keywords: ['contract', 'offer', 'acceptance', 'consideration', 'void agreement', 'samjhauta', 'pratiphal', 'capacity to contract'],
    ),
    LegalDocument(
      id: 'civil_002',
      titleEn: 'Property Inheritance and Succession',
      titleNp: 'सम्पत्ति उत्तराधिकार र हकवाला',
      sectionNumber: 'Section 46-80',
      category: 'Civil Law',
      contentEn: 'The inheritance of property in Nepal is governed by the Muluki Ain (Country Code) 2074, specifically the chapter on inheritance and succession. Upon the death of a person, his or her property devolves to the heirs according to the rules of succession. Heirs are classified into different classes based on their relationship to the deceased. The surviving spouse, children, and parents are primary heirs. Sons and daughters have equal rights to inherit ancestral property. A person may dispose of his or her self-acquired property through a will or testament. A testator must be of sound mind and at least eighteen years of age to make a valid will. The will must be in writing, signed by the testator, and attested by two witnesses. If a person dies without making a will, the property is distributed according to the laws of intestate succession. A legal heir may renounce his or her share of inheritance by executing a deed of renunciation.',
      contentNp: 'नेपालमा सम्पत्तिको उत्तराधिकार मुलुकी ऐन २०७४, विशेषगरी उत्तराधिकार र हकवालासम्बन्धी परिच्छेदद्वारा नियमन गरिन्छ। कुनै व्यक्तिको मृत्यु भएपछि उसको सम्पत्ति उत्तराधिकारको नियमअनुसार हकवालाहरूमा हस्तान्तरण हुन्छ। हकवालाहरूलाई मृतकसँगको सम्बन्धको आधारमा विभिन्न श्रेणीमा वर्गीकरण गरिन्छ। जीवित जीवनसाथी, सन्तान र आमाबाबु प्राथमिक हकवाला हुन्। छोरा र छोरीलाई पुर्खौली सम्पत्तिमा समान अधिकार हुन्छ। व्यक्तिले आफ्नो आर्जित सम्पत्ति वसीयत वा इच्छापत्रद्वारा व्यवस्थित गर्न सक्छ। वसीयत गर्ने व्यक्ति सचेत मनको र कम्तीमा अठार वर्ष उमेरको हुनुपर्दछ। वसीयत लिखित, वसीयतकर्ताद्वारा हस्ताक्षरित र दुई साक्षीद्वारा प्रमाणित हुनुपर्दछ। यदि व्यक्ति वसीयत नगरी मर्छ भने, सम्पत्ति नियमानुसारको उत्तराधिकारको कानूनअनुसार बाँडिन्छ। कानूनी हकवालाले त्यागपत्र कार्यान्वयन गरी आफ्नो हकको हिस्सा त्याग गर्न सक्छ।',
      keywords: ['inheritance', 'succession', 'will', 'testament', 'uttaradhikar', 'hakwala', 'muluki ain', 'intestate succession'],
    ),
    LegalDocument(
      id: 'civil_003',
      titleEn: 'Marriage and Divorce Law',
      titleNp: 'विवाह र सम्बन्धविच्छेद कानून',
      sectionNumber: 'Section 81-120',
      category: 'Civil Law',
      contentEn: 'Marriage in Nepal is governed by the Muluki Ain and specific marriage registration acts. A marriage is considered valid when both parties have attained the age of twenty years for males and twenty years for females, have given free consent, and are not within prohibited degrees of relationship. Marriage may be solemnized according to religious rites or through a civil ceremony. All marriages must be registered with the concerned government authority within thirty-five days of the ceremony. A spouse may file for divorce on grounds including mutual consent, adultery, cruelty, desertion for three years, mental illness for five years, or if the spouse has been missing for five years. The court may order alimony for the spouse and child support for minor children, taking into consideration the financial status of both parties and the needs of the children. Custody of children is determined based on the best interests of the child, with preference for the mother for children under five years.',
      contentNp: 'नेपालमा विवाह मुलुकी ऐन र विशेष विवाह दर्ता सम्बन्धी कानूनहरूद्वारा नियमन गरिन्छ। विवाह वैध मानिनको लागि दुवै पक्षको उमेर पुरुषको लागि बीस वर्ष र महिलाको लागि बीस वर्ष पुगेको, स्वतन्त्र सहमति प्राप्त भएको, र तिनीहरू निषेधित नाता सम्बन्धभित्र नपरेको हुनुपर्दछ। विवाह धार्मिक संस्कारअनुसार वा नागरिक विवाहको रूपमा सम्पन्न गर्न सकिन्छ। सबै विवाह समारोहको पैंतिस दिनभित्र सम्बन्धित सरकारी निकायमा दर्ता गराउनुपर्दछ। जीवनसाथीले आपसी सहमति, व्यभिचार, क्रूरता, तीन वर्षसम्म परित्याग, पाँच वर्षको मानसिक रोग, वा जीवनसाथी पाँच वर्षदेखि बेपत्ता भएको जस्ता आधारहरूमा सम्बन्धविच्छेदको लागि मुद्दा दायर गर्न सक्छ। अदालतले दुवै पक्षको आर्थिक स्थिति र सन्तानको आवश्यकतालाई ध्यानमा राखी जीवनसाथीको लागि भरणपोषण र नाबालिग सन्तानको लागि सन्तान भत्ताको आदेश दिन सक्छ। सन्तानको संरक्षकत्व सन्तानको सर्वोत्तम हितको आधारमा निर्धारण गरिन्छ, जसमा पाँच वर्षमुनिका सन्तानको लागि आमालाई प्राथमिकता दिइन्छ।',
      keywords: ['marriage', 'divorce', 'alimony', 'child custody', 'registration', 'bibah', 'sambandhabichhed', 'mutual consent'],
    ),
    LegalDocument(
      id: 'crim_001',
      titleEn: 'Offenses Against the Person',
      titleNp: 'व्यक्तिविरुद्धको अपराध',
      sectionNumber: 'Section 121-180',
      category: 'Criminal Law',
      contentEn: 'Offenses against the person include homicide, assault, battery, kidnapping, and offenses relating to sexual violence. Homicide is classified as murder, manslaughter, or culpable homicide not amounting to murder. Murder is the unlawful killing of a person with malice aforethought, punishable by life imprisonment or death in the most severe cases. Manslaughter is the unlawful killing without malice, which may be voluntary or involuntary. Assault is any act that intentionally causes another person to apprehend immediate unlawful violence. Battery involves the actual infliction of unlawful force on another person. Kidnapping involves taking a person away by force or fraud without their consent. These offenses are investigated by the Nepal Police and prosecuted by the government. The severity of punishment depends on the nature and gravity of the offense, the intent of the offender, and the circumstances surrounding the offense. Self-defense is a valid defense if the force used was proportionate to the threat.',
      contentNp: 'व्यक्तिविरुद्धको अपराधमा हत्या, प्रहार, कुटपिट, अपहरण र यौन हिंसासम्बन्धी अपराधहरू समावेश छन्। हत्यालाई ज्यान मार्ने, गैरइरादात्मक हत्या वा हत्याबराबर नहुने दोषी मानव वधको रूपमा वर्गीकृत गरिन्छ। ज्यान मार्नु भनेको पूर्वयोजनासहित कसैको अवैध हत्या हो, जसको लागि जन्मकैद वा अति गम्भीर अवस्थामा मृत्युदण्डको सजाय हुन सक्छ। गैरइरादात्मक हत्या दुर्भावनाविना भएको अवैध हत्या हो, जुन स्वैच्छिक वा अनैच्छिक हुन सक्छ। प्रहार भनेको कुनै कार्य हो जसले जानीबुझी अर्को व्यक्तिलाई तत्काल अवैध हिंसाको डर महसुस गराउँदछ। कुटपिटमा अर्को व्यक्तिमाथि अवैध बलको प्रयोग समावेश हुन्छ। अपहरणमा व्यक्तिलाई उसको सहमतिविना बल वा धोकाबाट लगी लुकाउने कार्य समावेश हुन्छ। यी अपराधहरूको नेपाल प्रहरीद्वारा अनुसन्धान गरिन्छ र सरकारद्वारा अभियोजन गरिन्छ। सजायको गम्भीरता अपराधको प्रकृति, अपराधीको आशय र अपराधको परिस्थितिमा निर्भर गर्दछ। आत्मरक्षा एक वैध बचाउ हो यदि प्रयोग गरिएको बल खतराको अनुपातमा थियो भने।',
      keywords: ['homicide', 'murder', 'assault', 'kidnapping', 'self-defense', 'hatya', 'manslaughter', 'culpable homicide'],
    ),
    LegalDocument(
      id: 'crim_002',
      titleEn: 'Offenses Against Property',
      titleNp: 'सम्पत्तिविरुद्धको अपराध',
      sectionNumber: 'Section 181-230',
      category: 'Criminal Law',
      contentEn: 'Offenses against property include theft, robbery, burglary, extortion, criminal trespass, and mischief. Theft involves the dishonest taking of movable property without the owner consent with the intent to permanently deprive the owner of it. Robbery is theft combined with the use of force or the threat of force against the victim. Burglary involves entering a building as a trespasser with the intent to commit theft, assault, or criminal damage. Extortion involves obtaining property or money through coercion or threats. Criminal trespass involves entering someone property without lawful authority. Under Nepalese law, these offenses are defined in the Muluki Ain and the Criminal Code Act. The punishment for these offenses ranges from fines to imprisonment, depending on the value of the property involved and the manner of commission. Repeat offenders are subject to enhanced penalties. Restitution of stolen property or compensation to the victim may be ordered.',
      contentNp: 'सम्पत्तिविरुद्धको अपराधमा चोरी, लुटपाट, सेंधमारी, जबरजस्ती असुली, आपराधिक अतिक्रमण र दुराचार समावेश छन्। चोरीमा मालिकको सहमतिविना उसलाई स्थायी रूपमा वञ्चित गर्ने आशयले चल सम्पत्ति बेइमानीपूर्वक लैजाने कार्य समावेश हुन्छ। लुटपाट भनेको पीडितविरुद्ध बल प्रयोग वा बल प्रयोगको धम्कीसहितको चोरी हो। सेंधमारीमा चोरी, प्रहार वा आपराधिक क्षति गर्ने आशयले अतिक्रमणकारीको रूपमा भवनमा प्रवेश गर्ने कार्य समावेश हुन्छ। जबरजस्ती असुलीमा जबरजस्ती वा धम्कीद्वारा सम्पत्ति वा पैसा प्राप्त गर्ने कार्य समावेश हुन्छ। आपराधिक अतिक्रमणमा कानूनी अधिकारविना कसैको सम्पत्तिमा प्रवेश गर्ने कार्य समावेश हुन्छ। नेपाली कानूनअनुसार, यी अपराधहरू मुलुकी ऐन र फौजदारी संहिता ऐनमा परिभाषित छन्। यी अपराधहरूको सजाय सम्पत्तिको मूल्य र अपराध गर्ने तरिकामा निर्भर गर्दै जरिवानादेखि कैदसम्म हुन सक्छ। पुनरावृत्ति अपराधीहरू बढी सजायको भागीदार हुन्छन्। चोरी भएको सम्पत्ति फिर्ता वा पीडितलाई क्षतिपूर्तिको आदेश दिन सकिन्छ।',
      keywords: ['theft', 'robbery', 'burglary', 'extortion', 'chori', 'lutpat', 'criminal trespass', 'property crime'],
    ),
    LegalDocument(
      id: 'crim_003',
      titleEn: 'Criminal Procedure and Bail',
      titleNp: 'फौजदारी कार्यविधि र धरौटी',
      sectionNumber: 'Section 231-290',
      category: 'Criminal Law',
      contentEn: 'The criminal procedure in Nepal is governed by the Criminal Procedure Code, which establishes the process for investigation, arrest, bail, trial, and appeal. A person may be arrested upon a warrant issued by a court or without a warrant in case of flagrant offenses. The arrested person must be produced before the nearest judicial authority within twenty-four hours of arrest. Bail may be granted by the court or the investigating officer depending on the nature and gravity of the offense. For bailable offenses, bail is a matter of right. For non-bailable offenses, bail is at the discretion of the court, considering factors such as the likelihood of the accused fleeing, tampering with evidence, or committing further offenses. The trial process involves the filing of a charge sheet, the examination of witnesses, the presentation of evidence, and the final arguments. The accused has the right to legal representation and the right to remain silent. Appeals against conviction may be filed in the High Court and the Supreme Court.',
      contentNp: 'नेपालको फौजदारी कार्यविधि फौजदारी कार्यविधि संहिताद्वारा नियमन गरिन्छ, जसले अनुसन्धान, गिरफ्तारी, धरौटी, मुद्दा सुनुवाइ र पुनरावेदनको प्रक्रिया स्थापित गर्दछ। व्यक्तिलाई अदालतले जारी गरेको वारण्टबमोजिम वा रङ्गेहात अपराधको अवस्थामा वारण्टविना पनि गिरफ्तार गर्न सकिन्छ। गिरफ्तार व्यक्तिलाई चौबीस घण्टाभित्र नजिकको न्यायिक अधिकारीसमक्ष पेश गर्नुपर्दछ। धरौटी अपराधको प्रकृति र गम्भीरताको आधारमा अदालत वा अनुसन्धान अधिकारीले प्रदान गर्न सक्छ। धरौटीमा छोड्न मिल्ने अपराधको लागि, धरौटी पाउने अधिकार हुन्छ। धरौटीमा नछोड्ने अपराधको लागि, धरौटी अदालतको विवेकमा निर्भर हुन्छ, जसमा अभियुक्तको फरार हुने, प्रमाण नष्ट गर्ने वा थप अपराध गर्ने सम्भावनालाई विचार गरिन्छ। मुद्दा सुनुवाइ प्रक्रियामा अभियोगपत्र दायर, साक्षीहरूको जाँच, प्रमाण पेश र अन्तिम बहस समावेश हुन्छ। अभियुक्तलाई कानूनी प्रतिनिधित्वको अधिकार र मौन रहने अधिकार हुन्छ। दोषी ठहरिएको विरुद्ध पुनरावेदन उच्च अदालत र सर्वोच्च अदालतमा दायर गर्न सकिन्छ।',
      keywords: ['criminal procedure', 'arrest', 'bail', 'trial', 'dharauti', 'charge sheet', 'appeal', 'legal representation'],
    ),
    LegalDocument(
      id: 'local_001',
      titleEn: 'Municipal Powers and Functions',
      titleNp: 'नगरपालिकाको अधिकार र कार्यहरू',
      sectionNumber: 'Section 1-60',
      category: 'Local Governance',
      contentEn: 'Municipalities in Nepal exercise executive, legislative, and financial powers as provided by the Constitution and the Local Government Operation Act. Each municipality has a Municipal Council composed of the mayor, deputy mayor, ward chairs, and ward members elected from each ward. The Municipal Council has the power to make laws, regulations, and bylaws on matters within its jurisdiction, including local infrastructure, sanitation, education, health, and cultural activities. The municipality is responsible for the preparation and implementation of annual development plans and budgets. It has the power to levy taxes, fees, and service charges within its territory, including property tax, vehicle tax, business tax, and entertainment tax. The municipality must also manage public utilities such as water supply, street lighting, waste management, and local roads. Decisions of the Municipal Council are executed by the municipal executive office headed by the chief administrative officer.',
      contentNp: 'नेपालका नगरपालिकाहरूले संविधान र स्थानीय सरकार सञ्चालन ऐनले प्रदत्त गरेबमोजिम कार्यकारी, विधायिकी र वित्तीय अधिकार प्रयोग गर्दछन्। प्रत्येक नगरपालिकामा प्रत्येक वडाबाट निर्वाचित मेयर, उपमेयर, वडाध्यक्ष र वडा सदस्यहरू मिलेको नगरसभा हुन्छ। नगरसभालाई स्थानीय पूर्वाधार, सरसफाइ, शिक्षा, स्वास्थ्य र सांस्कृतिक गतिविधिसहित आफ्नो अधिकारक्षेत्रभित्रका विषयहरूमा कानून, नियम र उपनियम बनाउने अधिकार हुन्छ। नगरपालिका वार्षिक विकास योजना र बजेटको तर्जुमा र कार्यान्वयनको लागि जिम्मेवार हुन्छ। यसलाई आफ्नो क्षेत्रभित्र सम्पत्ति कर, सवारी कर, व्यवसाय कर र मनोरञ्जन कर सहित कर, शुल्क र सेवा शुल्क लगाउने अधिकार हुन्छ। नगरपालिकाले खानेपानी, सडक बत्ती, फोहरमैला व्यवस्थापन र स्थानीय सडक जस्ता सार्वजनिक उपयोगिताहरूको पनि व्यवस्थापन गर्नुपर्दछ। नगरसभाका निर्णयहरू प्रमुख प्रशासकीय अधिकृतको नेतृत्वमा रहेको नगर कार्यपालिकाको कार्यालयद्वारा कार्यान्वयन गरिन्छ।',
      keywords: ['municipality', 'mayor', 'municipal council', 'property tax', 'nagarpalika', 'local government', 'development plan', 'ward'],
    ),
    LegalDocument(
      id: 'corp_001',
      titleEn: 'Company Registration and Incorporation',
      titleNp: 'कम्पनी दर्ता र निगमीकरण',
      sectionNumber: 'Section 1-80',
      category: 'Corporate Law',
      contentEn: 'The Companies Act of Nepal governs the registration, incorporation, and regulation of companies. A company may be registered as a private company, public company, or non-profit company. A private company must have at least one member and cannot exceed 100 members, and its shares are not traded publicly. A public company must have at least seven members and may offer shares to the public. The incorporation process involves reserving the company name, preparing the memorandum of association and articles of association, filing the required documents with the Office of the Company Registrar, and obtaining a certificate of incorporation. The memorandum of association contains the company name, registered office, objectives, and share capital. The articles of association set out the internal management rules. A company acquires legal personality upon incorporation, enabling it to own property, enter contracts, and sue or be sued in its own name. Foreign companies may establish branch offices or subsidiary companies in Nepal with approval.',
      contentNp: 'नेपालको कम्पनी ऐनले कम्पनीको दर्ता, निगमीकरण र नियमन गर्दछ। कम्पनी निजी कम्पनी, सार्वजनिक कम्पनी वा नाफा नकमाउने कम्पनीको रूपमा दर्ता गर्न सकिन्छ। निजी कम्पनीमा कम्तीमा एक सदस्य हुनुपर्दछ र १०० सदस्यभन्दा बढी हुन सक्दैन, र यसको शेयर सार्वजनिक रूपमा कारोबार हुँदैन। सार्वजनिक कम्पनीमा कम्तीमा सात सदस्य हुनुपर्दछ र यसले सर्वसाधारणलाई शेयर प्रस्ताव गर्न सक्छ। निगमीकरण प्रक्रियामा कम्पनीको नाम आरक्षित गर्ने, संस्थापन नियमावली र नियमावली तयार गर्ने, कम्पनी रजिष्ट्रारको कार्यालयमा आवश्यक कागजात दायर गर्ने र निगमीकरणको प्रमाणपत्र प्राप्त गर्ने समावेश छ। संस्थापन नियमावलीमा कम्पनीको नाम, दर्ता कार्यालय, उद्देश्य र शेयर पुँजी उल्लेख हुन्छ। नियमावलीले आन्तरिक व्यवस्थापन नियमहरू निर्धारण गर्दछ। कम्पनी निगमीकरणपछि कानूनी व्यक्तित्व प्राप्त गर्दछ, जसले गर्दा यो आफ्नो नाममा सम्पत्ति राख्न, सम्झौता गर्न र मुद्दा हाल्न वा हालिन सक्छ। विदेशी कम्पनीहरूले अनुमोदनपछि नेपालमा शाखा कार्यालय वा सहायक कम्पनी स्थापना गर्न सक्छन्।',
      keywords: ['company registration', 'incorporation', 'private company', 'public company', 'campani darta', 'memorandum of association', 'share capital', 'legal personality'],
    ),
    LegalDocument(
      id: 'hr_001',
      titleEn: 'Child Rights and Protection',
      titleNp: 'बाल अधिकार र संरक्षण',
      sectionNumber: 'Section 1-50',
      category: 'Human Rights',
      contentEn: 'The Children Act of Nepal guarantees the fundamental rights of every child, including the right to survival, development, protection, and participation. Every child has the right to a name and nationality, to live with their parents, to education, to health care, to rest and leisure, and to be protected from all forms of abuse, neglect, exploitation, and discrimination. The act prohibits child marriage, child labor, and corporal punishment. The minimum age for employment is fourteen years, and hazardous work is prohibited for all minors. Special provisions exist for children in conflict with the law, including juvenile justice procedures, separate detention facilities, and rehabilitation programs. The National Child Rights Council monitors the implementation of child rights and addresses violations. Children have the right to express their views in matters affecting them, and their views shall be given due weight. Any person who causes harm to a child may be subject to criminal liability.',
      contentNp: 'नेपालको बालबालिका सम्बन्धी ऐनले प्रत्येक बालबालिकाको मौलिक अधिकारको ग्यारेन्टी गर्दछ, जसमा बाँच्ने, विकास, संरक्षण र सहभागिताको हक समावेश छ। प्रत्येक बालबालिकालाई नाम र राष्ट्रियता, आमाबाबुसँग बस्ने, शिक्षा, स्वास्थ्य सेवा, आराम र मनोरञ्जन, र सबै प्रकारको दुर्व्यवहार, उपेक्षा, शोषण र भेदभावबाट संरक्षित हुने अधिकार छ। ऐनले बाल विवाह, बाल श्रम र शारीरिक दण्डलाई निषेध गर्दछ। रोजगारको लागि न्यूनतम उमेर चौध वर्ष हो, र सबै नाबालिगहरूको लागि जोखिमपूर्ण काम निषेधित छ। कानूनसँग द्वन्द्वमा रहेका बालबालिकाको लागि विशेष व्यवस्थाहरू छन्, जसमा किशोर न्याय प्रक्रिया, पृथक हिरासत सुविधा र पुनर्स्थापना कार्यक्रमहरू समावेश छन्। राष्ट्रिय बाल अधिकार परिषद्ले बाल अधिकारको कार्यान्वयनको अनुगमन गर्दछ र उल्लङ्घनहरूलाई सम्बोधन गर्दछ। बालबालिकालाई उनीहरूलाई असर गर्ने मामिलाहरूमा आफ्नो विचार व्यक्त गर्ने अधिकार छ, र तिनीहरूको विचारलाई उचित महत्त्व दिइनेछ। बालबालिकालाई हानि पुर्याउने कुनै पनि व्यक्ति आपराधिक दायित्वको अधीनमा हुन सक्छ।',
      keywords: ['child rights', 'child protection', 'child labor', 'juvenile justice', 'bal adhikar', 'child marriage', 'national child rights council', 'rehabilitation'],
    ),
  ];
}
