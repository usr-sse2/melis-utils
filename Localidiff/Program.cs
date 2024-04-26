using System.Text;
Encoding UTF16LE = new UnicodeEncoding(bigEndian: false, byteOrderMark: true, throwOnInvalidBytes: true);

Dictionary<string, string[]> LoadFromFile(string path)
{
  var dict = new Dictionary<string, string[]>();
  foreach (var strings in File.ReadAllLines(path, UTF16LE).Select(line => line.Split('\t')))
  {
    switch (strings[0])
    {
      case "//":
        dict["//"] = strings;
        break;
      case "{":
        dict[strings[1]] = strings;
        break;
      case var _ when strings.All(string.IsNullOrWhiteSpace):
        break;
      default:
        throw new NotImplementedException(strings[0]);
    }
  }
  return dict;
}

static string FormatLine(string[] values) => string.Join('\t', values);

void Compare(string oldPath, string newPath)
{
  var oldDict = LoadFromFile(oldPath);
  var newDict = LoadFromFile(newPath);

  foreach (var key in oldDict.Keys.Union(newDict.Keys).OrderBy(x => x))
  {
    var haveOld = oldDict.TryGetValue(key, out var oldValue);
    var haveNew = newDict.TryGetValue(key, out var newValue);
    if (!haveOld)
      Console.WriteLine($"ADD\t{FormatLine(newValue!)}");
    else if (!haveNew)
      Console.WriteLine($"REMOVE\t{FormatLine(oldValue!)}");
    else
    {
      if (newValue!.Length > oldValue!.Length)
        for (int i = oldValue.Length - 1; i < newValue.Length - 1; i++)
          Console.WriteLine($"ADD-LANGUAGE\t{key}\t{i}\t{newValue[i]}");
      else if(newValue.Length < oldValue.Length)
        for (int i = newValue.Length - 1; i < oldValue.Length - 1; i++)
          Console.WriteLine($"REMOVE-LANGUAGE\t{key}\t{i}\t{oldValue[i]}");

      for (int i = 1; i < Math.Min(oldValue!.Length, newValue!.Length) - 1; i++)
        if (oldValue[i] != newValue![i])
          Console.WriteLine($"CHANGE\t{key}\t{i}\t{oldValue[i]}\t{newValue[i]}");
    }
  }
}

if (args.Length == 7)
{
  // localidiff old.txt new.txt
  Console.WriteLine($"FILE\t{args[0]}");
  Compare(args[1], args[4]);
}
else if (args.Length == 2 && args[0] == "fix-bom")
{
  File.WriteAllText(args[1], File.ReadAllText(args[1], UTF16LE), UTF16LE);
}
else if (args.Length == 2 && args[0] == "apply")
{
  // localidiff apply patch
  var patch = File.ReadAllLines(args[1], UTF16LE);

  Dictionary<string, string[]>? dict = null;
  string? path = null;
  foreach (var line in patch)
  {
    var items = line.Split('\t');
    switch (items[0])
    {
      case "FILE":
        if (dict != null && path != null)
        {
          Console.WriteLine($"Writing {path}");
          File.WriteAllLines(path, dict.OrderByDescending(pair => pair.Key == "//").ThenBy(pair => pair.Key).Select(pair => FormatLine(pair.Value) + "\r"), UTF16LE);
        }
        path = items[1];
        Console.WriteLine($"Loading {path}");
        dict = LoadFromFile(path);
        break;

      case "ADD":
        Console.WriteLine($"Adding {FormatLine(items.Skip(1).ToArray())}");
        dict![items[2]] = items.Skip(1).ToArray();
        break;

      case "REMOVE":
        Console.WriteLine($"Removing {FormatLine(dict![items[2]])}");
        dict!.Remove(items[2]);
        break;

      case "CHANGE":
        if (dict!.TryGetValue(items[1], out string[]? values))
        {
          Console.WriteLine($"Replacing {values[int.Parse(items[2])]} with {items[4]}");
          values[int.Parse(items[2])] = items[4];
        }
        else
          Console.WriteLine($"{items[1]} ({items[3]} -> {items[4]}) not found for replace!");
        break;

      default:
        break;
    }
  }
  Console.WriteLine($"Writing {path}");
  File.WriteAllLines(path!, dict!.OrderByDescending(pair => pair.Key == "//").ThenBy(pair => pair.Key).Select(pair => FormatLine(pair.Value) + "\r"), UTF16LE);
}
else if (args.Length == 4 && args[0] == "copy-missing-strings")
{
    var dict = LoadFromFile(args[1]);
    var to = int.Parse(args[2]) + 2; // opening brace and key
    var from = int.Parse(args[3]) + 2;
    foreach (var (key, values) in dict)
        if (string.IsNullOrWhiteSpace(values[to]))
        {
            Console.WriteLine($"Replacing {values[to]} with {values[from]}");
            values[to] = values[from];
        }
    File.WriteAllLines(args[1]!, dict!.OrderByDescending(pair => pair.Key == "//").ThenBy(pair => pair.Key).Select(pair => FormatLine(pair.Value) + "\r"), UTF16LE);
}
else if (args.Length == 2 && args[0] == "replace-unsupported-characters")
{
  File.WriteAllText(args[1], File.ReadAllText(args[1], UTF16LE).Replace('і', 'i'), UTF16LE);
}
else if (args.Length == 2)
{
  Console.WriteLine($"FILE\t{Path.GetFileName(args[0])}");
  Compare(args[0], args[1]);
}
else
{
  Console.WriteLine("""
  Usage:
    localidiff 1.txt 2.txt
      Compares 2.txt to 1.txt and outputs the patch into the standard output

    localidiff unused 1.txt unused unused 2.txt unused unused
      The same but for usage as a git difftool
    
    localidiff apply patch.patch
      Applies patch.patch

    localidiff copy-missing-strings file.txt destination-language source-language
      Copies missing translations from source-language to destination-language in file.txt. Languages are specified as column numbers, where the first language (English) is 0.

    localidiff replace-unsupported-characters
      Replaces known characters missing in the font with their graphic analogs.

    localidiff fix-bom
      Adds byte-order mark to UTF-16LE file.
  """);
}
