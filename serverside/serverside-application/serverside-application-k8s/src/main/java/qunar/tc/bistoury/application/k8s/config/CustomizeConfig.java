package qunar.tc.bistoury.application.k8s.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

/**
 * @Author: liangtf
 * @Date: 2025/7/25 18:18
 * @Description:
 */
@Configuration
public class CustomizeConfig {

    @Value("${customize.config.ip:127.0.0.1}")
    private String ip;

    @Value("${customize.config.appName}")
    private String appName;

    @Value("${customize.config.workDir:/tmp}")
    private String workDir;

    public String getIp() {
        return ip;
    }

    public void setIp(String ip) {
        this.ip = ip;
    }

    public String getAppName() {
        return appName;
    }

    public void setAppName(String appName) {
        this.appName = appName;
    }

    public String getWorkDir() {
        return workDir;
    }

    public void setWorkDir(String workDir) {
        this.workDir = workDir;
    }

    @Override
    public String toString() {
        return "CustomizeConfig{" +
                "ip='" + ip + '\'' +
                ", appName='" + appName + '\'' +
                ", workDir='" + workDir + '\'' +
                '}';
    }
}
