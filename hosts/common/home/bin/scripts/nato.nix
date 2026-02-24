{
  name = "nato";
  desc = "Spell out words in NATO alphabet";
  usage = "nato WORD...";
  type = "python";
  body = ''
    import sys

    DICTIONARY = {
        "a": "Alfa",
        "b": "Bravo",
        "c": "Charlie",
        "d": "Delta",
        "e": "Echo",
        "f": "Foxtrot",
        "g": "Golf",
        "h": "Hotel",
        "i": "India",
        "j": "Juliett",
        "k": "Kilo",
        "l": "Lima",
        "m": "Mike",
        "n": "November",
        "o": "Oscar",
        "p": "Papa",
        "q": "Quebec",
        "r": "Romeo",
        "s": "Sierra",
        "t": "Tango",
        "u": "Uniform",
        "v": "Victor",
        "w": "Whiskey",
        "x": "X-ray",
        "y": "Yankee",
        "z": "Zulu",
        "1": "One",
        "2": "Two",
        "3": "Three",
        "4": "Four",
        "5": "Five",
        "6": "Six",
        "7": "Seven",
        "8": "Eight",
        "9": "Nine",
        "0": "Zero"
    }

    words = ' '.join(sys.argv[1:]).split()

    for word in words:
        letters = [DICTIONARY.get(char, char) for char in word.lower()]
        print(' '.join(letters))
  '';
}
