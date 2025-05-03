import * as k from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import * as fs from "jsr:@std/fs";

const defaultProfileName = "Default";
const baseConfig = {
  "profiles": [
    {
      "name": defaultProfileName,
      "selected": true,
      "virtual_hid_keyboard": { "keyboard_type_v2": "ansi" },
    },
  ],
} as const;

const rules = [
  k.rule("Change caps lock to control").manipulators([
    k.map({ key_code: "caps_lock" })
      .to({ key_code: "left_control" })
      .toIfAlone({ key_code: "caps_lock" }),
  ]),
  k.rule("Change fn to command").manipulators([
    k.map({ key_code: "fn" })
      .to({ key_code: "left_command" })
      .toIfAlone({ key_code: "fn" }),
  ]),
  k.rule("Tap command to toggle Kana/Eisuu").manipulators([
    k.withMapper(
      {
        "left_command": "japanese_eisuu",
        "right_command": "japanese_kana",
      } as const,
    )((command, lang) =>
      k.map({ key_code: command, modifiers: { optional: ["any"] } })
        .to({ key_code: command, lazy: true })
        .toIfAlone({ key_code: lang })
        .description(`Tap ${command} alone to switch to ${lang}`)
        .parameters({ "basic.to_if_held_down_threshold_milliseconds": 100 })
    ),
  ]),
];

const configFilePath = Deno.env.get("HOME") +
  "/.config/karabiner/karabiner.json";

fs.existsSync(configFilePath) && Deno.removeSync(configFilePath);
fs.ensureFileSync(configFilePath);
Deno.writeTextFileSync(configFilePath, JSON.stringify(baseConfig), {
  create: false,
});

k.writeToProfile({
  name: defaultProfileName,
  karabinerJsonPath: configFilePath,
}, rules);
