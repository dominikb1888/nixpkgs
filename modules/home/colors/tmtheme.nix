# Generic tmTheme generator. Takes a color attrset with semantic names and produces
# tmTheme XML suitable for syntect-based tools (bat, yazi file preview, etc.).
#
# Color assignments follow cross-theme consensus and the "spending contrast" principle:
# color only where it resolves visual ambiguity between elements that could be confused.
#
# Accent mapping rationale:
#   green   → strings, literal content (strongest convention, 9/11 themes)
#   cyan    → support/library, regex, escapes, attributes ("external" elements)
#   blue    → functions, tags, type annotations (navigation targets)
#   yellow  → classes, types, entity names (structural definitions)
#   magenta → keywords, storage (language scaffolding)
#   red     → errors, invalid, interpolation boundaries (danger/attention)
#   orange  → constants, imports, special values
#   violet  → numbers, parameters, language variables, namespaces

{ themeName, colors }:

let
  inherit (colors)
    bg
    surface
    muted
    subtle
    fg
    emphasis
    bright
    red
    green
    yellow
    blue
    magenta
    cyan
    orange
    violet
    ;

  # Helpers for building plist XML
  kv = key: val: ''
    				<key>${key}</key>
    				<string>${val}</string>'';

  rule =
    {
      name,
      scope,
      foreground ? null,
      background ? null,
      fontStyle ? null,
    }:
    ''
      		<dict>
      			<key>name</key>
      			<string>${name}</string>
      			<key>scope</key>
      			<string>${scope}</string>
      			<key>settings</key>
      			<dict>
      ${if foreground != null then kv "foreground" foreground else ""}${
        if background != null then kv "background" background else ""
      }${if fontStyle != null then kv "fontStyle" fontStyle else ""}
      			</dict>
      		</dict>
    '';

  rules = [
    # Comments (universal: muted, lowest visual weight) --------------------------------------------

    {
      name = "Comment";
      scope = "comment, meta.documentation";
      foreground = muted;
    }

    # Strings & literal content (green -- 9/11 themes agree) ---------------------------------------

    {
      name = "String";
      scope = "string";
      foreground = green;
    }
    {
      name = "Regexp";
      scope = "string.regexp";
      foreground = cyan;
    }
    {
      name = "Escape character";
      scope = "constant.character.escape";
      foreground = cyan;
    }
    {
      name = "Interpolation punctuation";
      scope = "punctuation.section.interpolation.begin, punctuation.section.interpolation.end, punctuation.section.embedded.begin, punctuation.section.embedded.end";
      foreground = red;
    }

    # Constants & values ---------------------------------------------------------------------------

    {
      name = "Number";
      scope = "constant.numeric";
      foreground = violet;
    }
    {
      name = "Language constant";
      scope = "constant.language";
      foreground = orange;
    }
    {
      name = "Other constant";
      scope = "constant.character, constant.other";
      foreground = orange;
    }
    {
      name = "Preprocessor";
      scope = "meta.preprocessor";
      foreground = orange;
    }
    {
      name = "Format placeholder";
      scope = "constant.other.placeholder";
      foreground = orange;
    }

    # Variables (fg -- 9/11 themes leave variables uncolored) --------------------------------------

    {
      name = "Variable";
      scope = "variable";
      foreground = fg;
    }
    {
      name = "Function call";
      scope = "variable.function";
      foreground = blue;
    }
    {
      name = "Language variable";
      scope = "variable.language";
      foreground = violet;
    }
    {
      name = "Parameter";
      scope = "variable.parameter";
      foreground = violet;
    }

    # Keywords & storage (magenta -- most common keyword hue across themes) ------------------------

    {
      name = "Keyword";
      scope = "keyword";
      foreground = magenta;
    }
    {
      name = "Import";
      scope = "meta.import keyword, keyword.control.import, keyword.control.import.from, keyword.other.import, keyword.control.at-rule.include, keyword.control.at-rule.import";
      foreground = orange;
    }
    {
      name = "Operator";
      scope = "keyword.operator";
      foreground = subtle;
    }
    {
      name = "Storage";
      scope = "storage";
      foreground = magenta;
    }
    {
      name = "Storage modifier";
      scope = "storage.modifier";
      foreground = emphasis;
    }
    {
      name = "Storage type";
      scope = "storage.type";
      foreground = blue;
    }

    # Entity names (yellow for types/classes, blue for functions) ----------------------------------

    {
      name = "Entity name";
      scope = "entity.name";
      foreground = yellow;
    }
    {
      name = "Function name";
      scope = "entity.name.function";
      foreground = blue;
    }
    {
      name = "Inherited class";
      scope = "entity.other.inherited-class";
      foreground = yellow;
    }
    {
      name = "Namespace";
      scope = "entity.name.namespace, entity.name.module";
      foreground = violet;
    }
    {
      name = "Tag name";
      scope = "entity.name.tag";
      foreground = blue;
    }
    {
      name = "Attribute name";
      scope = "entity.other.attribute-name";
      foreground = cyan;
    }
    {
      name = "Section heading";
      scope = "entity.name.section";
      foreground = orange;
    }

    # Support / library (cyan -- "external" elements) ----------------------------------------------

    {
      name = "Library type";
      scope = "support, support.type, support.class";
      foreground = cyan;
    }
    {
      name = "Library function";
      scope = "support.function";
      foreground = cyan;
    }
    {
      name = "Constructor";
      scope = "support.function.construct, keyword.other.new";
      foreground = red;
    }
    {
      name = "Exception type";
      scope = "support.type.exception";
      foreground = orange;
    }

    # Punctuation (muted/subtle -- structural scaffolding) -----------------------------------------

    {
      name = "Tag punctuation";
      scope = "punctuation.definition.tag.html, punctuation.definition.tag.begin, punctuation.definition.tag.end";
      foreground = muted;
    }
    {
      name = "String quotes";
      scope = "punctuation.definition.string";
      foreground = fg;
    }
    {
      name = "Brackets and braces";
      scope = "meta.brace.square, punctuation.section.brackets, meta.brace.round, meta.brace.curly, punctuation.section, punctuation.section.block, punctuation.definition.parameters, punctuation.section.group";
      foreground = subtle;
    }
    {
      name = "Variable sigil";
      scope = "punctuation.definition.variable";
      foreground = magenta;
    }
    {
      name = "Continuation";
      scope = "punctuation.separator.continuation";
      foreground = red;
    }

    # Invalid --------------------------------------------------------------------------------------

    {
      name = "Invalid";
      scope = "invalid";
      foreground = bright;
      background = red;
    }
    {
      name = "Deprecated";
      scope = "invalid.deprecated";
      foreground = bright;
      background = orange;
    }

    # Special --------------------------------------------------------------------------------------

    {
      name = "Special method";
      scope = "keyword.other.special-method";
      foreground = orange;
    }

    # CSS ------------------------------------------------------------------------------------------

    {
      name = "CSS: color value";
      scope = "support.constant.color, invalid.deprecated.color.w3c-non-standard-color-name.scss";
      foreground = yellow;
    }
    {
      name = "CSS: selector";
      scope = "meta.selector.css";
      foreground = subtle;
    }
    {
      name = "CSS: tag";
      scope = "entity.name.tag.css, entity.name.tag.scss, source.less keyword.control.html.elements, source.sass keyword.control.untitled";
      foreground = blue;
    }
    {
      name = "CSS: .class";
      scope = "entity.other.attribute-name.class";
      foreground = yellow;
    }
    {
      name = "CSS: #id";
      scope = "entity.other.attribute-name.id";
      foreground = yellow;
    }
    {
      name = "CSS: :pseudo";
      scope = "entity.other.attribute-name.pseudo-element, entity.other.attribute-name.tag.pseudo-element, entity.other.attribute-name.pseudo-class, entity.other.attribute-name.tag.pseudo-class";
      foreground = cyan;
    }

    # HTML -----------------------------------------------------------------------------------------

    {
      name = "HTML: meta tags";
      scope = "text.html.basic meta.tag.other.html, text.html.basic meta.tag.any.html, text.html.basic meta.tag.block.any, text.html.basic meta.tag.inline.any, text.html.basic meta.tag.structure.any.html, text.html.basic source.js.embedded.html, punctuation.separator.key-value.html";
      foreground = subtle;
    }
    {
      name = "HTML: attribute name";
      scope = "text.html.basic entity.other.attribute-name.html, meta.tag.xml entity.other.attribute-name";
      foreground = cyan;
    }

    # JSON -----------------------------------------------------------------------------------------

    {
      name = "JSON: key";
      scope = "support.type.property-name, meta.structure.dictionary.key";
      foreground = blue;
    }

    # Diff -----------------------------------------------------------------------------------------

    {
      name = "Diff: header";
      scope = "meta.diff, meta.diff.header";
      foreground = muted;
    }
    {
      name = "Diff: range";
      scope = "meta.diff.range";
      foreground = blue;
    }
    {
      name = "Diff: deleted";
      scope = "markup.deleted";
      foreground = red;
    }
    {
      name = "Diff: changed";
      scope = "markup.changed";
      foreground = yellow;
    }
    {
      name = "Diff: inserted";
      scope = "markup.inserted";
      foreground = green;
    }

    # Markup ---------------------------------------------------------------------------------------

    {
      name = "Markup: heading";
      scope = "markup.heading, punctuation.definition.heading.markdown";
      foreground = yellow;
      fontStyle = "bold";
    }
    {
      name = "Markup: quote";
      scope = "markup.quote";
      foreground = green;
    }
    {
      name = "Markup: italic";
      scope = "markup.italic";
      fontStyle = "italic";
    }
    {
      name = "Markup: bold";
      scope = "markup.bold";
      fontStyle = "bold";
    }
    {
      name = "Markup: raw / code";
      scope = "markup.raw, markup.raw.inline, markup.raw.block";
      foreground = green;
    }
    {
      name = "Markup: link";
      scope = "markup.underline.link.markdown, meta.link.reference constant.other.reference.link.markdown";
      foreground = cyan;
    }
    {
      name = "Markup: reference";
      scope = "constant.other.reference.link.markdown";
      foreground = violet;
    }
    {
      name = "Markup: warning";
      scope = "markup.warning";
      foreground = yellow;
    }
    {
      name = "Markup: error";
      scope = "markup.error";
      foreground = red;
    }

    # JavaScript -----------------------------------------------------------------------------------

    {
      name = "JavaScript: variables";
      scope = "variable.other.readwrite.js, variable.other.object.js, variable.other.constant.js";
      foreground = fg;
    }

    # Nix ------------------------------------------------------------------------------------------

    {
      name = "Nix: attribute name";
      scope = "entity.other.attribute-name.single.nix, entity.other.attribute-name.multipart.nix";
      foreground = fg;
    }
  ];

  rulesXml = builtins.concatStringsSep "" (map rule rules);
in
''
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
  	<key>name</key>
  	<string>${themeName}</string>
  	<key>settings</key>
  	<array>
  		<dict>
  			<key>settings</key>
  			<dict>
  				<key>background</key>
  				<string>${bg}</string>
  				<key>caret</key>
  				<string>${emphasis}</string>
  				<key>foreground</key>
  				<string>${fg}</string>
  				<key>gutter</key>
  				<string>${surface}</string>
  				<key>gutterForeground</key>
  				<string>${muted}</string>
  				<key>invisibles</key>
  				<string>${muted}</string>
  				<key>lineHighlight</key>
  				<string>${surface}40</string>
  				<key>misspelling</key>
  				<string>${red}</string>
  				<key>selection</key>
  				<string>${surface}</string>
  				<key>selectionBorder</key>
  				<string>${muted}</string>
  			</dict>
  		</dict>
  ${rulesXml}
  	</array>
  	<key>uuid</key>
  	<string>00000000-0000-0000-0000-000000000000</string>
  </dict>
  </plist>
''
