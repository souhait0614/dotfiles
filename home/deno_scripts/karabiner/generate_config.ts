import * as k from "https://deno.land/x/karabinerts@1.31.0/deno.ts";
import * as fs from "jsr:@std/fs@1.0.21";
import baseConfig from "./base_config.json" with { type: "json" };

const DEFAULT_PROFILE_NAME = "Default";
const CONFIG_FILE_PATH = Deno.env.get("HOME") +
  "/.config/karabiner/karabiner.json";

const changeCapsLockToControl = k.rule("Change caps lock to control")
  .manipulators([
    k.map({ key_code: "caps_lock", modifiers: { optional: ["any"] } })
      .to({ key_code: "left_control" }),
  ]);

const changeFnToCommand = k.rule("Change fn to command").manipulators([
  k.map({ key_code: "fn", modifiers: { optional: ["any"] } })
    .to({ key_code: "left_command" }),
]);

const tapCommandToToggleKanaEisuu = k.rule("Tap command to toggle Kana/Eisuu")
  .manipulators([
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
  ]);

const quitRequireDoubleTap = k.rule("Quit require double tap").manipulators([
  k.mapDoubleTap("q", "command")
    .to("q", "command")
    .singleTap(null),
]);

const rules = [
  changeCapsLockToControl,
  changeFnToCommand,
  tapCommandToToggleKanaEisuu,
  quitRequireDoubleTap,
];

fs.existsSync(CONFIG_FILE_PATH) && Deno.removeSync(CONFIG_FILE_PATH);
fs.ensureFileSync(CONFIG_FILE_PATH);
Deno.writeTextFileSync(CONFIG_FILE_PATH, JSON.stringify(baseConfig), {
  create: false,
});

k.writeToProfile({
  name: DEFAULT_PROFILE_NAME,
  karabinerJsonPath: CONFIG_FILE_PATH,
}, rules);
