import { mkdirSync, mkdtempSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import * as k from "karabiner.ts";

const rules = [
  k
    .rule("Change caps lock to control")
    .manipulators([
      k
        .map({ key_code: "caps_lock", modifiers: { optional: ["any"] } })
        .to({ key_code: "left_control" }),
    ]),
  k
    .rule("Change fn to command")
    .manipulators([
      k.map({ key_code: "fn", modifiers: { optional: ["any"] } }).to({ key_code: "left_command" }),
    ]),
  k.rule("Tap command to toggle Kana/Eisuu").manipulators([
    k.withMapper({
      left_command: "japanese_eisuu",
      right_command: "japanese_kana",
    } as const)((command, language) =>
      k
        .map({ key_code: command, modifiers: { optional: ["any"] } })
        .to({ key_code: command, lazy: true })
        .toIfAlone({ key_code: language })
        .description(`Tap ${command} alone to switch to ${language}`)
        .parameters({ "basic.to_if_held_down_threshold_milliseconds": 100 }),
    ),
  ]),
  k
    .rule("Quit require double tap")
    .manipulators([k.mapDoubleTap("q", "command").to("q", "command").singleTap(null)]),
];

const profile: k.KarabinerProfile & {
  virtual_hid_keyboard: { keyboard_type_v2: "ansi" };
} = {
  name: "Default",
  selected: true,
  virtual_hid_keyboard: { keyboard_type_v2: "ansi" },
  complex_modifications: k.complexModifications(rules),
};

const config: k.KarabinerConfig = {
  profiles: [profile],
  global: {
    show_in_menu_bar: false,
    show_profile_name_in_menu_bar: false,
  },
};

const configDirectory = join(homedir(), ".config", "karabiner");
const configPath = join(configDirectory, "karabiner.json");
mkdirSync(configDirectory, { recursive: true });
const temporaryDirectory = mkdtempSync(join(configDirectory, ".generate-"));
try {
  const temporaryPath = join(temporaryDirectory, "karabiner.json");
  writeFileSync(temporaryPath, `${JSON.stringify(config, null, 2)}\n`, { mode: 0o600 });
  renameSync(temporaryPath, configPath);
} finally {
  rmSync(temporaryDirectory, { recursive: true });
}
console.log(`Karabiner-Elements configuration written to ${configPath}`);
