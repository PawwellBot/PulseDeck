#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::cmp::Ordering;
use std::env;
use std::fs;
use std::io;
use std::path::PathBuf;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct DisplayMode {
    label: String,
    width: u32,
    height: u32,
    refresh_rate: f64,
    preferred: bool,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct AssistResult {
    tone: String,
    title: String,
    detail: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct Monitor {
    id: i64,
    name: String,
    description: String,
    connector_type: String,
    width: u32,
    height: u32,
    refresh_rate: f64,
    x: i64,
    y: i64,
    scale: f64,
    enabled: bool,
    primary: bool,
    modes: Vec<DisplayMode>,
    assist: AssistResult,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct BackupEntry {
    path: String,
    created_at: String,
    bytes: u64,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct DisplaySnapshot {
    source: String,
    hyprland_available: bool,
    generated_at: String,
    config_path: String,
    config_preview: Vec<String>,
    monitors: Vec<Monitor>,
    backups: Vec<BackupEntry>,
    config_errors: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct ApplyResult {
    config_path: String,
    backup_path: Option<String>,
    reload_output: String,
    config_errors: String,
    applied_at: String,
}

#[derive(Debug, Clone, Default, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct SetupPersistence {
    setup_completed: bool,
    completed_at: Option<String>,
    admin_permission_requested: bool,
    admin_permission_granted: bool,
    admin_permission_checked_at: Option<String>,
    admin_permission_message: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct SetupCheck {
    label: String,
    detail: String,
    passed: bool,
    required: bool,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct SetupStatus {
    first_run: bool,
    setup_completed: bool,
    setup_path: String,
    config_path: String,
    hyprctl_available: bool,
    pkexec_available: bool,
    hyprland_session: bool,
    admin_permission_requested: bool,
    admin_permission_granted: bool,
    admin_permission_checked_at: Option<String>,
    admin_permission_message: Option<String>,
    checked_at: String,
    checks: Vec<SetupCheck>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct AdminPermissionResult {
    granted: bool,
    message: String,
    checked_at: String,
    setup_status: SetupStatus,
}

#[tauri::command]
fn get_setup_status() -> Result<SetupStatus, String> {
    build_setup_status()
}

#[tauri::command]
async fn request_admin_permissions() -> Result<AdminPermissionResult, String> {
    let result = tauri::async_runtime::spawn_blocking(request_admin_permissions_blocking)
        .await
        .map_err(|error| format!("Admin permission task failed: {error}"))?;

    result
}

#[tauri::command]
fn complete_setup() -> Result<SetupStatus, String> {
    let mut state = read_setup_state()?;

    if command_available("pkexec") && !state.admin_permission_granted {
        return Err(
            "Administrator permission must be granted once before setup can finish.".to_string(),
        );
    }

    state.setup_completed = true;
    state.completed_at = Some(now_iso_like());
    write_setup_state(&state)?;
    build_setup_status()
}

#[tauri::command]
fn get_display_snapshot() -> Result<DisplaySnapshot, String> {
    let monitors = read_hyprland_monitors()?;
    let config_preview = monitors.iter().map(config_line_for_monitor).collect();
    let config_errors = run_hyprctl(&["configerrors"]).unwrap_or_else(|error| error);

    Ok(DisplaySnapshot {
        source: "hyprctl monitors -j".to_string(),
        hyprland_available: true,
        generated_at: now_iso_like(),
        config_path: config_path()?.display().to_string(),
        config_preview,
        monitors,
        backups: list_backup_entries().unwrap_or_default(),
        config_errors,
    })
}

#[tauri::command]
fn write_monitor_config(lines: Vec<String>) -> Result<ApplyResult, String> {
    if lines.is_empty() {
        return Err("No monitor config lines were generated.".to_string());
    }

    if lines
        .iter()
        .any(|line| !line.trim_start().starts_with("monitor ="))
    {
        return Err("PulseDeck only writes Hyprland monitor lines.".to_string());
    }

    let config_path = config_path()?;
    let backup_path = backup_existing_config(&config_path)?;

    if let Some(parent) = config_path.parent() {
        fs::create_dir_all(parent).map_err(|error| {
            format!(
                "Unable to create Hyprland config directory {}: {error}",
                parent.display()
            )
        })?;
    }

    fs::write(&config_path, format!("{}\n", lines.join("\n"))).map_err(|error| {
        format!(
            "Unable to write Hyprland monitor config {}: {error}",
            config_path.display()
        )
    })?;

    let reload_output = run_hyprctl(&["reload"]).unwrap_or_else(|error| error);
    let config_errors = run_hyprctl(&["configerrors"]).unwrap_or_else(|error| error);

    Ok(ApplyResult {
        config_path: config_path.display().to_string(),
        backup_path: backup_path.map(|path| path.display().to_string()),
        reload_output,
        config_errors,
        applied_at: now_iso_like(),
    })
}

fn request_admin_permissions_blocking() -> Result<AdminPermissionResult, String> {
    let mut state = read_setup_state()?;

    if state.admin_permission_granted {
        let checked_at = state
            .admin_permission_checked_at
            .clone()
            .unwrap_or_else(now_iso_like);
        let message =
            "Administrator permission was already granted once. PulseDeck will not ask again."
                .to_string();

        state.admin_permission_requested = true;
        state.admin_permission_checked_at = Some(checked_at.clone());
        state.admin_permission_message = Some(message.clone());
        write_setup_state(&state)?;

        return Ok(AdminPermissionResult {
            granted: true,
            message,
            checked_at,
            setup_status: build_setup_status()?,
        });
    }

    let checked_at = now_iso_like();
    let pkexec_available = command_available("pkexec");

    let (granted, message) = if pkexec_available {
        match Command::new("pkexec").arg("true").output() {
            Ok(output) if output.status.success() => (
                true,
                "Administrator permission was granted once. PulseDeck will not ask again."
                    .to_string(),
            ),
            Ok(output) => {
                let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
                let detail = if stderr.is_empty() {
                    "The administrator prompt was cancelled or denied.".to_string()
                } else {
                    stderr
                };

                (false, detail)
            }
            Err(error) => (
                false,
                format!("Unable to open the administrator prompt with pkexec: {error}"),
            ),
        }
    } else {
        (
            false,
            "pkexec is not installed, so PulseDeck cannot show a graphical administrator prompt."
                .to_string(),
        )
    };

    state.admin_permission_requested = true;
    state.admin_permission_granted = granted;
    state.admin_permission_checked_at = Some(checked_at.clone());
    state.admin_permission_message = Some(message.clone());
    write_setup_state(&state)?;

    Ok(AdminPermissionResult {
        granted,
        message,
        checked_at,
        setup_status: build_setup_status()?,
    })
}

fn read_hyprland_monitors() -> Result<Vec<Monitor>, String> {
    let output = Command::new("hyprctl")
        .args(["monitors", "-j"])
        .output()
        .map_err(|error| format!("Unable to run hyprctl monitors -j: {error}"))?;

    if !output.status.success() {
        return Err(format!(
            "hyprctl monitors -j failed: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }

    let value: Value = serde_json::from_slice(&output.stdout)
        .map_err(|error| format!("Unable to parse hyprctl monitor JSON: {error}"))?;

    let monitors = value
        .as_array()
        .ok_or_else(|| "hyprctl did not return a monitor list.".to_string())?
        .iter()
        .map(monitor_from_value)
        .collect::<Result<Vec<_>, _>>()?;

    Ok(monitors)
}

fn monitor_from_value(value: &Value) -> Result<Monitor, String> {
    let name = string_field(value, "name").unwrap_or_else(|| "unknown".to_string());
    let width = u32_field(value, "width").unwrap_or(0);
    let height = u32_field(value, "height").unwrap_or(0);
    let refresh_rate = f64_field(value, "refreshRate").unwrap_or(0.0);
    let x = i64_field(value, "x").unwrap_or(0);
    let y = i64_field(value, "y").unwrap_or(0);
    let scale = f64_field(value, "scale").unwrap_or(1.0);
    let id = i64_field(value, "id").unwrap_or(0);
    let enabled = !bool_field(value, "disabled").unwrap_or(false);
    let primary = bool_field(value, "focused").unwrap_or(false);
    let connector_type = connector_type(&name);
    let description = monitor_description(value, &name);
    let mut modes = mode_list(value, width, height, refresh_rate);

    mark_preferred_modes(&mut modes, width, height);

    let mut monitor = Monitor {
        id,
        name,
        description,
        connector_type,
        width,
        height,
        refresh_rate,
        x,
        y,
        scale,
        enabled,
        primary,
        modes,
        assist: AssistResult {
            tone: "unknown".to_string(),
            title: "Checking".to_string(),
            detail: "PulseDeck is still classifying this display.".to_string(),
        },
    };

    monitor.assist = classify_assist(&monitor);
    Ok(monitor)
}

fn monitor_description(value: &Value, fallback: &str) -> String {
    if let Some(description) = string_field(value, "description") {
        if !description.trim().is_empty() {
            return description;
        }
    }

    let make = string_field(value, "make").unwrap_or_default();
    let model = string_field(value, "model").unwrap_or_default();
    let combined = format!("{make} {model}").trim().to_string();

    if combined.is_empty() {
        fallback.to_string()
    } else {
        combined
    }
}

fn mode_list(value: &Value, width: u32, height: u32, refresh_rate: f64) -> Vec<DisplayMode> {
    let mut modes = value
        .get("availableModes")
        .and_then(Value::as_array)
        .into_iter()
        .flatten()
        .filter_map(Value::as_str)
        .filter_map(parse_mode)
        .collect::<Vec<_>>();

    if width > 0
        && height > 0
        && refresh_rate > 0.0
        && !modes.iter().any(|mode| {
            mode.width == width
                && mode.height == height
                && (mode.refresh_rate - refresh_rate).abs() < 0.1
        })
    {
        modes.push(DisplayMode {
            label: format_mode_label(width, height, refresh_rate),
            width,
            height,
            refresh_rate,
            preferred: false,
        });
    }

    modes.sort_by(compare_modes);
    modes.dedup_by(|left, right| {
        left.width == right.width
            && left.height == right.height
            && (left.refresh_rate - right.refresh_rate).abs() < 0.1
    });

    modes
}

fn mark_preferred_modes(modes: &mut [DisplayMode], current_width: u32, current_height: u32) {
    let same_resolution_has_120 = modes.iter().any(|mode| {
        mode.width == current_width && mode.height == current_height && mode.refresh_rate >= 119.5
    });

    for mode in modes {
        mode.preferred = mode.refresh_rate >= 119.5
            && (!same_resolution_has_120
                || (mode.width == current_width && mode.height == current_height));
    }
}

fn parse_mode(input: &str) -> Option<DisplayMode> {
    let clean = input.trim().trim_end_matches("Hz");
    let (resolution, refresh) = clean.split_once('@')?;
    let (width, height) = resolution.split_once('x')?;
    let width = width.parse::<u32>().ok()?;
    let height = height.parse::<u32>().ok()?;
    let refresh_rate = refresh.parse::<f64>().ok()?;

    Some(DisplayMode {
        label: format_mode_label(width, height, refresh_rate),
        width,
        height,
        refresh_rate,
        preferred: false,
    })
}

fn compare_modes(left: &DisplayMode, right: &DisplayMode) -> Ordering {
    right
        .refresh_rate
        .partial_cmp(&left.refresh_rate)
        .unwrap_or(Ordering::Equal)
        .then_with(|| right.width.cmp(&left.width))
        .then_with(|| right.height.cmp(&left.height))
}

fn classify_assist(monitor: &Monitor) -> AssistResult {
    if monitor.refresh_rate >= 119.5 {
        return AssistResult {
            tone: "good".to_string(),
            title: "High refresh applied".to_string(),
            detail: format!(
                "{} is already running at {}.",
                monitor.name,
                format_refresh(monitor.refresh_rate)
            ),
        };
    }

    let same_resolution_120 = monitor.modes.iter().any(|mode| {
        mode.width == monitor.width && mode.height == monitor.height && mode.refresh_rate >= 119.5
    });

    if same_resolution_120 {
        return AssistResult {
            tone: "ready".to_string(),
            title: "120Hz available".to_string(),
            detail: "The current resolution advertises a 120Hz or faster mode. PulseDeck can write it to Hyprland.".to_string(),
        };
    }

    let lower_resolution_120 = monitor.modes.iter().any(|mode| {
        mode.refresh_rate >= 119.5 && mode.width <= monitor.width && mode.height <= monitor.height
    });

    if lower_resolution_120 {
        return AssistResult {
            tone: "warn".to_string(),
            title: "Lower resolution needed".to_string(),
            detail: "A 120Hz mode is advertised, but not at the current resolution. HDMI bandwidth, adapter limits, or EDID data may be involved.".to_string(),
        };
    }

    if monitor.connector_type == "HDMI" {
        return AssistResult {
            tone: "blocked".to_string(),
            title: "Not advertised over HDMI".to_string(),
            detail: "This input is not advertising a 120Hz mode. Check the monitor input, HDMI cable, dock, adapter, GPU port, and EDID information.".to_string(),
        };
    }

    AssistResult {
        tone: "unknown".to_string(),
        title: "120Hz not advertised".to_string(),
        detail: "Hyprland did not report a 120Hz mode for this display. PulseDeck will not claim it can force unsupported hardware modes.".to_string(),
    }
}

fn config_line_for_monitor(monitor: &Monitor) -> String {
    let best_mode = monitor
        .modes
        .iter()
        .find(|mode| {
            mode.width == monitor.width
                && mode.height == monitor.height
                && mode.refresh_rate >= 119.5
        })
        .or_else(|| monitor.modes.iter().find(|mode| mode.preferred));

    let (width, height, refresh_rate) = best_mode
        .map(|mode| (mode.width, mode.height, mode.refresh_rate))
        .unwrap_or((monitor.width, monitor.height, monitor.refresh_rate));

    format!(
        "monitor = {}, {}x{}@{}, {}x{}, {}",
        monitor.name,
        width,
        height,
        trim_float(refresh_rate),
        monitor.x,
        monitor.y,
        trim_float(monitor.scale)
    )
}

fn config_path() -> Result<PathBuf, String> {
    let home = env::var_os("HOME").ok_or_else(|| "HOME is not set.".to_string())?;
    Ok(PathBuf::from(home).join(".config/hypr/monitors.conf"))
}

fn backup_dir() -> Result<PathBuf, String> {
    let home = env::var_os("HOME").ok_or_else(|| "HOME is not set.".to_string())?;
    Ok(PathBuf::from(home).join(".config/hypr/pulsedeck-backups"))
}

fn app_config_dir() -> Result<PathBuf, String> {
    if let Some(path) = env::var_os("XDG_CONFIG_HOME") {
        return Ok(PathBuf::from(path).join("pulsedeck"));
    }

    let home = env::var_os("HOME").ok_or_else(|| "HOME is not set.".to_string())?;
    Ok(PathBuf::from(home).join(".config/pulsedeck"))
}

fn setup_state_path() -> Result<PathBuf, String> {
    Ok(app_config_dir()?.join("setup.json"))
}

fn read_setup_state() -> Result<SetupPersistence, String> {
    let path = setup_state_path()?;
    let contents = match fs::read_to_string(&path) {
        Ok(contents) => contents,
        Err(error) if error.kind() == io::ErrorKind::NotFound => {
            return Ok(SetupPersistence::default());
        }
        Err(error) => {
            return Err(format!(
                "Unable to read setup state {}: {error}",
                path.display()
            ));
        }
    };

    serde_json::from_str(&contents)
        .map_err(|error| format!("Unable to parse setup state {}: {error}", path.display()))
}

fn write_setup_state(state: &SetupPersistence) -> Result<(), String> {
    let path = setup_state_path()?;

    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|error| {
            format!(
                "Unable to create setup directory {}: {error}",
                parent.display()
            )
        })?;
    }

    let contents = serde_json::to_string_pretty(state)
        .map_err(|error| format!("Unable to serialize setup state: {error}"))?;

    fs::write(&path, format!("{contents}\n"))
        .map_err(|error| format!("Unable to write setup state {}: {error}", path.display()))
}

fn build_setup_status() -> Result<SetupStatus, String> {
    let state = read_setup_state()?;
    let setup_path = setup_state_path()?;
    let config_path = config_path()?;
    let hyprctl_available = command_available("hyprctl");
    let pkexec_available = command_available("pkexec");
    let hyprland_session = is_hyprland_session();

    let checks = vec![
        SetupCheck {
            label: "Hyprland session".to_string(),
            detail: if hyprland_session {
                "PulseDeck can see a Hyprland session environment.".to_string()
            } else {
                "Start PulseDeck from inside Hyprland for live monitor control.".to_string()
            },
            passed: hyprland_session,
            required: true,
        },
        SetupCheck {
            label: "hyprctl".to_string(),
            detail: if hyprctl_available {
                "hyprctl is available for monitor scans, reloads, and config validation."
                    .to_string()
            } else {
                "Install or expose hyprctl on PATH before applying display changes.".to_string()
            },
            passed: hyprctl_available,
            required: true,
        },
        SetupCheck {
            label: "Administrator authorization".to_string(),
            detail: if state.admin_permission_granted {
                "Administrator permission was granted once; setup will not ask again.".to_string()
            } else if pkexec_available {
                "PulseDeck can open a pkexec prompt for the one-time setup authorization."
                    .to_string()
            } else {
                "pkexec is missing; PulseDeck can still edit user monitor config but cannot ask for admin authorization.".to_string()
            },
            passed: state.admin_permission_granted,
            required: pkexec_available,
        },
        SetupCheck {
            label: "Monitor config path".to_string(),
            detail: config_path.display().to_string(),
            passed: true,
            required: true,
        },
    ];

    Ok(SetupStatus {
        first_run: !state.setup_completed,
        setup_completed: state.setup_completed,
        setup_path: setup_path.display().to_string(),
        config_path: config_path.display().to_string(),
        hyprctl_available,
        pkexec_available,
        hyprland_session,
        admin_permission_requested: state.admin_permission_requested,
        admin_permission_granted: state.admin_permission_granted,
        admin_permission_checked_at: state.admin_permission_checked_at,
        admin_permission_message: state.admin_permission_message,
        checked_at: now_iso_like(),
        checks,
    })
}

fn command_available(name: &str) -> bool {
    env::var_os("PATH")
        .map(|paths| env::split_paths(&paths).any(|dir| dir.join(name).is_file()))
        .unwrap_or(false)
}

fn is_hyprland_session() -> bool {
    if env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_some() {
        return true;
    }

    env::var("XDG_CURRENT_DESKTOP")
        .map(|desktop| desktop.to_ascii_lowercase().contains("hyprland"))
        .unwrap_or(false)
}

fn backup_existing_config(config_path: &PathBuf) -> Result<Option<PathBuf>, String> {
    if !config_path.exists() {
        return Ok(None);
    }

    let dir = backup_dir()?;
    fs::create_dir_all(&dir).map_err(|error| {
        format!(
            "Unable to create backup directory {}: {error}",
            dir.display()
        )
    })?;

    let backup_path = dir.join(format!("monitors-{}.conf", epoch_seconds()));
    fs::copy(config_path, &backup_path).map_err(|error| {
        format!(
            "Unable to back up {} to {}: {error}",
            config_path.display(),
            backup_path.display()
        )
    })?;

    Ok(Some(backup_path))
}

fn list_backup_entries() -> Result<Vec<BackupEntry>, String> {
    let dir = backup_dir()?;
    let entries = match fs::read_dir(&dir) {
        Ok(entries) => entries,
        Err(error) if error.kind() == io::ErrorKind::NotFound => return Ok(Vec::new()),
        Err(error) => {
            return Err(format!(
                "Unable to read backup directory {}: {error}",
                dir.display()
            ));
        }
    };

    let mut backups = entries
        .filter_map(Result::ok)
        .filter_map(|entry| {
            let metadata = entry.metadata().ok()?;
            if !metadata.is_file() {
                return None;
            }

            let created_at = metadata
                .modified()
                .ok()
                .map(system_time_label)
                .unwrap_or_else(|| "unknown".to_string());

            Some(BackupEntry {
                path: entry.path().display().to_string(),
                created_at,
                bytes: metadata.len(),
            })
        })
        .collect::<Vec<_>>();

    backups.sort_by(|left, right| right.created_at.cmp(&left.created_at));
    Ok(backups)
}

fn run_hyprctl(args: &[&str]) -> Result<String, String> {
    let output = Command::new("hyprctl")
        .args(args)
        .output()
        .map_err(|error| format!("Unable to run hyprctl {}: {error}", args.join(" ")))?;

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();

    if output.status.success() {
        if stdout.is_empty() {
            Ok("Command completed without output.".to_string())
        } else {
            Ok(stdout)
        }
    } else if stderr.is_empty() {
        Err(format!("hyprctl {} failed.", args.join(" ")))
    } else {
        Err(stderr)
    }
}

fn string_field(value: &Value, key: &str) -> Option<String> {
    value.get(key)?.as_str().map(ToString::to_string)
}

fn bool_field(value: &Value, key: &str) -> Option<bool> {
    value.get(key)?.as_bool()
}

fn i64_field(value: &Value, key: &str) -> Option<i64> {
    value.get(key)?.as_i64()
}

fn u32_field(value: &Value, key: &str) -> Option<u32> {
    let number = value.get(key)?.as_u64()?;
    u32::try_from(number).ok()
}

fn f64_field(value: &Value, key: &str) -> Option<f64> {
    value.get(key)?.as_f64()
}

fn connector_type(name: &str) -> String {
    let upper = name.to_ascii_uppercase();

    if upper.starts_with("HDMI") {
        "HDMI".to_string()
    } else if upper.starts_with("DP-") || upper.starts_with("DISPLAYPORT") {
        "DisplayPort".to_string()
    } else if upper.starts_with("EDP") || upper.starts_with("E-DP") {
        "Internal".to_string()
    } else if upper.starts_with("VGA") {
        "VGA".to_string()
    } else {
        "Unknown".to_string()
    }
}

fn format_mode_label(width: u32, height: u32, refresh_rate: f64) -> String {
    format!("{}x{} @ {}", width, height, format_refresh(refresh_rate))
}

fn format_refresh(refresh_rate: f64) -> String {
    format!("{}Hz", trim_float(refresh_rate))
}

fn trim_float(value: f64) -> String {
    if (value.fract()).abs() < 0.01 {
        format!("{value:.0}")
    } else {
        format!("{value:.2}")
    }
}

fn epoch_seconds() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or_default()
}

fn now_iso_like() -> String {
    Utc::now().to_rfc3339()
}

fn system_time_label(time: SystemTime) -> String {
    DateTime::<Utc>::from(time).to_rfc3339()
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            complete_setup,
            get_display_snapshot,
            get_setup_status,
            request_admin_permissions,
            write_monitor_config
        ])
        .run(tauri::generate_context!())
        .expect("error while running PulseDeck");
}
