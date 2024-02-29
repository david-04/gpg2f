import static java.lang.Math.max;
import static java.lang.Math.min;
import static java.lang.Math.round;
import static java.lang.System.getenv;
import static java.util.Optional.empty;
import static java.util.Optional.of;
import static java.util.Optional.ofNullable;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Container;
import java.awt.Cursor;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Timer;
import java.util.TimerTask;
import java.util.function.Function;
import java.util.stream.Collectors;

import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.WindowConstants;
import javax.swing.border.EmptyBorder;

//----------------------------------------------------------------------------------------------------------------------
// Display a pop-up window with the given message. Supported options:
//----------------------------------------------------------------------------------------------------------------------
// background-color=#ffd232 .... background color as hex representation
// fly-in-duration=2s .......... duration during which the dialog slides into view
// font=Segoe UI ............... font name
// font-size=24 ................ font size in points
// padding=20 .................. horizontal and vertical padding between the text and the window borders
// timeout=10s ................. auto-hide the notification (supported units: s, m, h, d, duration is float)
// window-position=NE .......... place the window N (top-center), NE (top-right), E (middle-right), SE, S, SW, W or NW
//----------------------------------------------------------------------------------------------------------------------

public class PopUpWindow {

    private final Color backgroundColor;
    private final Optional<Long> flyInDuration;
    private final Font font;
    private final String message;
    private final int padding;
    private final Color textColor;
    private final String windowPosition;

    //------------------------------------------------------------------------------------------------------------------
    // Initialization
    //------------------------------------------------------------------------------------------------------------------

    public PopUpWindow(String message, Map<String, String> config) {
        this.backgroundColor = getConfigColor(config, "background-color", new Color(250, 172, 20));
        this.flyInDuration = getConfigValue(config, "fly-in-duration", PopUpWindow::parseDuration, of(0L));
        this.font = ofNullable(config.get("font")).map(Font::decode).orElse(
                new JLabel("").getFont()).deriveFont(getConfigValue(config, "font-size", Float::parseFloat, 24f))
                .deriveFont(Font.PLAIN);
        this.message = message;
        this.padding = getConfigValue(config, "padding", Integer::parseInt, 20).intValue();
        this.textColor = backgroundColor.getGreen() + backgroundColor.getRed() + backgroundColor.getBlue() < 383
                ? Color.WHITE
                : Color.BLACK;
        this.windowPosition = ofNullable(config.get("window-position")).orElse("C").toUpperCase();
    }

    //------------------------------------------------------------------------------------------------------------------
    // Main program
    //------------------------------------------------------------------------------------------------------------------

    public static void main(String[] args) throws Exception {
        String message = Arrays.stream(args).collect(Collectors.joining(" ")).trim();
        if (0 < message.length()) {
            Map<String, String> config = getConfiguration();
            new PopUpWindow(message, config).populateAndShow();
            scheduleTimeout(config);
            try {
                BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(System.in));
                while (0 <= bufferedReader.readLine().length())
                    ;
            } catch (Exception exception) {
                System.exit(0);
            }
        }
    }

    //------------------------------------------------------------------------------------------------------------------
    // Parse the configuration from the environment variables
    //------------------------------------------------------------------------------------------------------------------

    private static Map<String, String> getConfiguration() {
        Map<String, String> options = new HashMap<>();
        String[] environmentVariableNames = { "GPG2F_DEFAULT_NOTIFICATION_OPTIONS", "NOTIFICATION_OPTIONS" };
        for (String environmentVariableName : environmentVariableNames) {
            String data = ofNullable(getenv(environmentVariableName)).orElse("").trim();
            while (!data.isEmpty()) {
                int equalsIndex = data.indexOf('=');
                if (0 <= equalsIndex) {
                    String key = data.substring(0, equalsIndex).trim();
                    data = data.substring(equalsIndex + 1);
                    int endIndex = getValueEndIndex(data);
                    options.put(key, data.substring(0, endIndex));
                    data = data.substring(endIndex).trim();
                } else {
                    data = "";
                }
            }
        }
        return options;
    }

    private static int getValueEndIndex(String data) {
        int spaceIndex = data.indexOf(' ');
        if (0 <= spaceIndex) {
            int equalsIndex = data.indexOf('=', spaceIndex);
            if (0 <= equalsIndex) {
                for (int index = equalsIndex - 1; 0 <= index; index--) {
                    if (data.charAt(index) == ' ') {
                        return index;
                    }
                }
            }
        }
        return data.length();
    }

    //------------------------------------------------------------------------------------------------------------------
    // Schedule the timeout
    //------------------------------------------------------------------------------------------------------------------

    private static void scheduleTimeout(Map<String, String> config) {
        TimerTask timerTask = new TimerTask() {
            @Override
            public void run() {
                System.exit(0);
            }
        };
        getConfigValue(config, "timeout", PopUpWindow::parseDuration, Optional.<Long>empty())
                .ifPresent(timeoutMs -> new Timer().schedule(timerTask, timeoutMs));
    }

    private static Optional<Long> parseDuration(String timeout) {
        Map<String, Long> unitToMultiplier = new HashMap<>();
        unitToMultiplier.put("s", 1000L);
        unitToMultiplier.put("m", 1000L * 60);
        unitToMultiplier.put("h", 1000L * 60 * 60);
        unitToMultiplier.put("d", 1000L * 60 * 60 * 24);
        if (0 < timeout.length()) {
            String unit = timeout.substring(timeout.length() - 1);
            if (Character.isDigit(unit.charAt(0))) {
                unit = "s";
                timeout += unit;
            }
            Long multiplier = unitToMultiplier.get(unit);
            if (null != multiplier) {
                try {
                    return of((long) (Float.parseFloat(timeout.substring(0, timeout.length() - 1)) * multiplier));
                } catch (Exception exception) {
                    exception.printStackTrace(System.err);
                }
            }
        }
        return empty();
    }

    //------------------------------------------------------------------------------------------------------------------
    // Get configuration values
    //------------------------------------------------------------------------------------------------------------------

    private static <T> T getConfigValue(Map<String, String> config, String key, Function<String, T> parse,
            T defaultValue) {
        try {
            return ofNullable(config.get(key)).map(String::trim).map(parse).orElse(defaultValue);
        } catch (Exception ignored) {
            ignored.printStackTrace(System.err);
            return defaultValue;
        }
    }

    private static Color getConfigColor(Map<String, String> config, String key, Color defaultValue) {
        try {
            String value = getConfigValue(config, key, String::trim, "");
            if (!value.isEmpty()) {
                return value.startsWith("#") ? Color.decode(value) : Color.decode("#" + value);
            }
        } catch (Exception ignored) {
            ignored.printStackTrace(System.err);
        }
        return defaultValue;

    }

    //------------------------------------------------------------------------------------------------------------------
    // Create the window
    //------------------------------------------------------------------------------------------------------------------

    private void populateAndShow() {
        JFrame frame = new JFrame("gpg2f");
        Container contentPane = frame.getContentPane();
        contentPane.setLayout(new BorderLayout());
        contentPane.add(createOuterPanel(), BorderLayout.CENTER);
        contentPane.setBackground(this.backgroundColor);
        frame.setUndecorated(true);
        frame.pack();
        frame.setLocationByPlatform(true);
        positionWindow(frame);
        frame.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
        frame.setFocusableWindowState(false);
        frame.setVisible(true);
        frame.toFront();
        frame.setAlwaysOnTop(true);
    }

    //------------------------------------------------------------------------------------------------------------------
    // Create the window content
    //------------------------------------------------------------------------------------------------------------------

    private JPanel createOuterPanel() {
        JPanel panel = createPanel();
        panel.setBorder(new EmptyBorder(padding, padding, padding, padding));
        panel.add(createMessagePanel(), BorderLayout.CENTER);
        panel.add(createCloseButtonPanel(), BorderLayout.EAST);
        return panel;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Create the panel with the message
    //------------------------------------------------------------------------------------------------------------------

    private JPanel createMessagePanel() {
        JLabel label = createLabel(message);
        label.setBorder(new EmptyBorder(0, 0, 0, padding));
        JPanel panel = createPanel();
        panel.add(label, BorderLayout.CENTER);
        return panel;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Create the panel with the close button
    //------------------------------------------------------------------------------------------------------------------

    private JPanel createCloseButtonPanel() {
        JLabel label = createLabel("×");
        label.setCursor(new Cursor(Cursor.HAND_CURSOR));
        label.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                System.exit(0);
            }
        });
        JPanel panel = createPanel();
        panel.add(label, BorderLayout.NORTH);
        panel.add(createPanel(), BorderLayout.CENTER);
        return panel;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Create a panel
    //------------------------------------------------------------------------------------------------------------------

    private JPanel createPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(backgroundColor);
        return panel;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Create a label
    //------------------------------------------------------------------------------------------------------------------

    private JLabel createLabel(String message) {
        JLabel label = new JLabel(message);
        label.setFont(font);
        label.setForeground(textColor);
        return label;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Position the window
    //------------------------------------------------------------------------------------------------------------------

    private void positionWindow(JFrame frame) {
        Dimension screenSize = frame.getToolkit().getScreenSize();
        int screenWidth = screenSize.width;
        int screenHeight = screenSize.height;
        int halfScreenWidth = round(screenWidth * 0.5f);
        int halfScreenHeight = round(screenHeight * 0.5f);
        int windowWidth = frame.getWidth();
        int windowHeight = frame.getHeight();
        int halfWindowWidth = round(windowWidth * 0.5f);
        int halfWindowHeight = round(windowHeight * 0.5f);
        int paddingCenter = screenHeight / 15;
        int paddingCorner = 75;
        if (windowPosition.matches("N|NORTH")) {
            scheduleFlyInDuration(frame, halfScreenWidth - halfWindowWidth, -windowHeight,
                    halfScreenWidth - halfWindowWidth, paddingCenter);
        } else if (windowPosition.matches("NE|NORTHEAST|NORTH-EAST")) {
            scheduleFlyInDuration(frame, screenWidth + windowWidth, paddingCorner,
                    screenWidth - windowWidth - paddingCorner, paddingCorner);
        } else if (windowPosition.matches("E|EAST")) {
            scheduleFlyInDuration(frame, screenWidth + windowWidth, halfScreenHeight - halfWindowHeight,
                    screenWidth - windowWidth - paddingCenter, halfScreenHeight - halfWindowHeight);
        } else if (windowPosition.matches("SE|SOUTHEAST|SOUTH-EAST")) {
            scheduleFlyInDuration(frame, screenWidth + windowWidth, screenHeight - windowHeight - paddingCorner,
                    screenWidth - windowWidth - paddingCorner, screenHeight - windowHeight - paddingCorner);
        } else if (windowPosition.matches("S|SOUTH")) {
            scheduleFlyInDuration(frame, halfScreenWidth - halfWindowWidth, screenHeight + windowHeight,
                    halfScreenWidth - halfWindowWidth, screenHeight - windowHeight - paddingCenter);
        } else if (windowPosition.matches("SW|SOUTHWEST|SOUTH-WEST")) {
            scheduleFlyInDuration(frame, -windowWidth, screenHeight - windowHeight - paddingCorner, paddingCorner,
                    screenHeight - windowHeight - paddingCorner);
        } else if (windowPosition.matches("W|WEST")) {
            scheduleFlyInDuration(frame, -windowWidth, halfScreenHeight - halfWindowHeight, paddingCenter,
                    halfScreenHeight - halfWindowHeight);
        } else if (windowPosition.matches("NW|NORTHWEST|NORTH-WEST")) {
            scheduleFlyInDuration(frame, -windowWidth, paddingCorner, paddingCorner, paddingCorner);
        } else {
            scheduleFlyInDuration(frame, halfScreenWidth - halfWindowWidth, halfScreenHeight - halfWindowHeight,
                    halfScreenWidth - halfWindowWidth, halfScreenHeight - halfWindowHeight);
        }
    }

    private void scheduleFlyInDuration(JFrame frame, int startColumn, int startRow, int endColumn, int endRow) {
        if (flyInDuration.isPresent()) {
            final long start = System.currentTimeMillis();
            Timer timer = new Timer();
            timer.scheduleAtFixedRate(new TimerTask() {
                @Override
                public void run() {
                    float percent = (System.currentTimeMillis() - start) * 1f / flyInDuration.get();
                    double smoothedPercent = min(1, max(0, Math.sqrt(percent / 2) * 1.42));
                    frame.setLocation((int) round(startColumn + (endColumn - startColumn) * smoothedPercent),
                            (int) round(startRow + (endRow - startRow) * smoothedPercent));
                    if (1 < percent) {
                        timer.cancel();
                    }
                }
            }, 0, 3);
        } else {
            frame.setLocation(endColumn, endRow);
        }
    }

}
