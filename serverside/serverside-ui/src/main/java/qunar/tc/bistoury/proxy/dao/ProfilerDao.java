package qunar.tc.bistoury.proxy.dao;

import qunar.tc.bistoury.serverside.bean.Profiler;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * @author cai.wen created on 2019/10/30 14:52
 */
public interface ProfilerDao {

    void changeState(Profiler.State state, String profilerId);

    void prepareProfiler(Profiler profiler);

    Optional<Profiler> getLastRecord(String app, String agentId);

    Profiler getRecordByProfilerId(String profilerId);

    List<Profiler> getRecords(String app, String agentId, LocalDateTime startTime);

}
