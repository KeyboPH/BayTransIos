import SwiftUI

enum BayTransData {
    static let characters: [BaybayinCharacter] = [
        BaybayinCharacter(baybayin: "ᜀ", latin: "a", pronunciation: "a", note: "Independent vowel."),
        BaybayinCharacter(baybayin: "ᜁ", latin: "i/e", pronunciation: "i or e", note: "Independent vowel for i and e sounds."),
        BaybayinCharacter(baybayin: "ᜂ", latin: "u/o", pronunciation: "u or o", note: "Independent vowel for u and o sounds."),
        BaybayinCharacter(baybayin: "ᜊ", latin: "ba", pronunciation: "ba", note: "Base consonant with inherent a."),
        BaybayinCharacter(baybayin: "ᜃ", latin: "ka", pronunciation: "ka", note: "Use kudlit for ki/ku."),
        BaybayinCharacter(baybayin: "ᜇ", latin: "da/ra", pronunciation: "da or ra", note: "Historically used for both d and r."),
        BaybayinCharacter(baybayin: "ᜄ", latin: "ga", pronunciation: "ga", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜑ", latin: "ha", pronunciation: "ha", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜎ", latin: "la", pronunciation: "la", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜋ", latin: "ma", pronunciation: "ma", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜈ", latin: "na", pronunciation: "na", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜅ", latin: "nga", pronunciation: "nga", note: "Distinct consonant for the ng sound."),
        BaybayinCharacter(baybayin: "ᜉ", latin: "pa", pronunciation: "pa", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜐ", latin: "sa", pronunciation: "sa", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜆ", latin: "ta", pronunciation: "ta", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜏ", latin: "wa", pronunciation: "wa", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜌ", latin: "ya", pronunciation: "ya", note: "Base consonant."),
        BaybayinCharacter(baybayin: "ᜒ", latin: "kudlit i/e", pronunciation: "i or e mark", note: "Placed above a consonant."),
        BaybayinCharacter(baybayin: "ᜓ", latin: "kudlit u/o", pronunciation: "u or o mark", note: "Placed below a consonant."),
        BaybayinCharacter(baybayin: "᜔", latin: "virama", pronunciation: "vowel killer", note: "Modern mark used to cancel the inherent a."),
        BaybayinCharacter(baybayin: "᜵", latin: ",", pronunciation: "comma", note: "Baybayin punctuation."),
        BaybayinCharacter(baybayin: "᜶", latin: ".", pronunciation: "period", note: "Baybayin punctuation.")
    ]

    static let latinWords = ["araw", "bayan", "diwa", "gabi", "haligi", "kalayaan", "lahi", "mahal", "ngiti", "puso", "sulat", "tala", "wika", "yaman", "buhay", "dangal", "liwanag", "panahon"]

    static var baybayinWords: [String] {
        latinWords.map { BaybayinTranslator.shared.translateLatinToBaybayin($0) }
    }

    static let hardArticleLatin = "ang wikang filipino ay yaman ng bayan. sa bawat titik, buhay ang alaala ng ating lahi. mahalin natin ang sariling sulat at kultura."

    static var hardArticleBaybayin: String {
        BaybayinTranslator.shared.translateLatinToBaybayin(hardArticleLatin)
    }

    static let writingPrompts = [
        "Sumulat ng maikling kuwento tungkol sa isang batang unang natutong bumasa ng Baybayin.",
        "Gumawa ng tula tungkol sa araw, dagat, at alaala ng sariling bayan.",
        "Isulat ang isang pangako sa sarili gamit ang mga salitang nagpapakita ng dangal at pag-asa.",
        "Gumawa ng maikling sanaysay tungkol sa kahalagahan ng wika at kultura.",
        "Maglarawan ng isang sinaunang pamayanan at kung paano ginagamit ang sulat sa araw-araw."
    ]

    static let letterPrompts = [
        "Sumulat ng liham pasasalamat para sa iyong ina.",
        "Sumulat ng maikling mensahe para sa isang kaibigan na matagal mo nang hindi nakita.",
        "Sumulat ng liham pagmamahal para sa iyong kasintahan.",
        "Sumulat ng liham paumanhin para sa taong nasaktan mo.",
        "Sumulat ng liham para sa sarili mo sa hinaharap."
    ]

    static let modules: [LearningModule] = [
        LearningModule(title: "Foundations", sections: [
            LearningSection(title: "What Baybayin Is", body: "Baybayin is a precolonial Philippine writing system used for languages such as Tagalog. It is an abugida: each consonant character carries an inherent /a/ vowel unless a mark changes or removes that vowel."),
            LearningSection(title: "Why It Matters", body: "Learning Baybayin connects writing practice with cultural memory. Contemporary learners use it for education, art, signage, tattoos, digital posts, and cultural advocacy."),
            LearningSection(title: "Limits of Translation", body: "Baybayin is phonetic, not a direct letter-for-letter English cipher. Foreign sounds such as f, v, z, j, x, and q often need Filipino spelling adaptation before conversion.")
        ]),
        LearningModule(title: "Reading System", sections: [
            LearningSection(title: "Vowels", body: "The independent vowels are ᜀ for a, ᜁ for i/e, and ᜂ for u/o. Baybayin does not always distinguish e from i or o from u."),
            LearningSection(title: "Consonants", body: "A consonant character is normally read with an a sound: ᜊ is ba, ᜃ is ka, ᜋ is ma, and so on."),
            LearningSection(title: "Kudlit Marks", body: "The upper kudlit ᜒ changes the vowel to i/e, while the lower kudlit ᜓ changes it to u/o. Modern writing often uses ᜔ to remove the vowel for final consonants."),
            LearningSection(title: "Da and Ra", body: "The character ᜇ can represent both da and ra depending on context. This is one reason Baybayin-to-Latin conversion can be ambiguous.")
        ]),
        LearningModule(title: "Writing Practice", sections: [
            LearningSection(title: "Write by Syllable", body: "Break words into sounds first. The word mahal becomes ma-ha-l. With a final consonant mark it becomes ᜋᜑᜎ᜔."),
            LearningSection(title: "Ng Sound", body: "The ng sound has its own character: ᜅ. The syllable nga is ᜅ, while ng without a vowel can be written as ᜅ᜔."),
            LearningSection(title: "Punctuation", body: "Traditional punctuation includes ᜵ and ᜶. This app maps comma to ᜵ and period to ᜶.")
        ]),
        LearningModule(title: "Contemporary Use", sections: [
            LearningSection(title: "Modern Context", body: "Modern Baybayin appears in education, design, social media, local branding, and cultural events. Digital tools make practice easier while preserving offline access."),
            LearningSection(title: "Respectful Use", body: "Use Baybayin with attention to meaning. For names, brands, and public designs, verify spelling and pronunciation before publishing."),
            LearningSection(title: "Practical Workflow", body: "Draft the Filipino or phonetic text, convert it, review syllables, then practice reading it aloud. Repetition builds recognition faster than memorizing isolated charts.")
        ])
    ]
}
