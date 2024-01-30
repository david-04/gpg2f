import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Container;
import java.awt.Dimension;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.stream.Collectors;

import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.WindowConstants;
import javax.swing.border.EmptyBorder;

public class PopUpWindow {
    public static void main(String[] args) throws Exception {
        String message = 0 < args.length ? Arrays.stream(args).collect(Collectors.joining(" "))
                : System.getenv("GPG2F_NOTIFICATION_TEXT");
        if (null != message && 0 < message.trim().length()) {
            JFrame frame = new JFrame("gpg2f");
            Container contentPane = frame.getContentPane();
            contentPane.setLayout(new BorderLayout());
            JLabel label = new JLabel(message);
            label.setBorder(new EmptyBorder(20, 20, 20, 20));
            label.setFont(label.getFont().deriveFont(20f));
            contentPane.add(label, BorderLayout.CENTER);
            contentPane.setBackground(new Color(255, 200, 0));
            contentPane.setBackground(new Color(255, 210, 50));
            frame.pack();
            frame.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
            frame.setLocationByPlatform(true);
            Dimension screenSize = frame.getToolkit().getScreenSize();
            frame.setLocation(Math.round(screenSize.width * 0.5f) - frame.getWidth() / 2,
                    Math.round(screenSize.height * 0.333f) - frame.getHeight() / 2);
            frame.setFocusableWindowState(false);
            frame.setVisible(true);
            frame.toFront();
            frame.setAlwaysOnTop(true);

            try {
                BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(System.in));
                while (bufferedReader.readLine())
                    ;
            } catch (Exception exception) {
                System.exit(0);
            }
        }
    }
}
