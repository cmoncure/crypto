export english

const english_frequency = (Char => Float32) [
    'E' => 12.02,
    'T' => 9.10,
    'A' => 8.12,
    'O' => 7.68,
    'I' => 7.31,
    'N' => 6.95,
    'S' => 6.28,
    'R' => 6.02,
    'H' => 5.92,
    'D' => 4.32,
    'L' => 3.98,
    'U' => 2.88,
    'C' => 2.71,
    'M' => 2.61,
    'F' => 2.30,
    'Y' => 2.11,
    'W' => 2.09,
    'G' => 2.03,
    'P' => 1.82,
    'B' => 1.49,
    'V' => 1.11,
    'K' => 0.69,
    'X' => 0.17,
    'Q' => 0.11,
    'J' => 0.10,
    'Z' => 0.07
    ]

const english_words = [
  "LIKE",
  "THE",
  "AND",
  "THAT",
  "HAVE",
  "WITH",
  "FROM",
  "YOUR",
  "NOT",
  "THEY",
  "SAY",
  "SHE",
  "WOULD",
  "THERE",
  "THEIR",
  "WHAT"
  ]

const languages = [
  "english" => (english_frequency, english_words)
  ]

function character_frequency_score (test_str::ASCIIString, glyph_frequency_dict::Dict)
  score = float32(0.0)
  test_str = uppercase(test_str)
  for glyph = keys(glyph_frequency_dict)
    count = zero(Int32)
    idx = one(Int32)

    while idx < sizeof(test_str)
      if test_str[idx] == glyph
        count += 1
      end
      idx += 1
    end

    frequency = (count / sizeof(test_str))
    difference = 100 * frequency - glyph_frequency_dict[glyph]
    score += glyph_frequency_dict[glyph] - abs(difference)

  end
  return score
end

function common_substrings_score (test_str::ASCIIString, common_words::Vector{ASCIIString})
  score = int32(0)
  test_str = uppercase(test_str)
  for substring = common_words
      if contains(test_str, substring)
        score += length(substring) * 4
      end
  end
  return score
end

function score_candidate_language(test_str::ASCIIString, language::String)
  score = character_frequency_score(test_str, languages[language][1])
  score += common_substrings_score(test_str, languages[language][2])
  return score
end
