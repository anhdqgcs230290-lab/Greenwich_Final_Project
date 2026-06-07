// admin-web/src/pages/IncidentMap.tsx
export default function IncidentMap() {
    return (
        <div style={{ padding: '20px', backgroundColor: '#e6f7ff', borderRadius: '8px' }}>
            <h2>🗺️ Bản Đồ Nhiệt Sự Cố Đô Thị (Incident Heatmap)</h2>
            <p>Khu vực này sau này sẽ tích hợp Google Maps / Mapbox để hiển thị tọa độ GPS.</p>
            <div style={{ width: '100%', height: '300px', backgroundColor: '#bae7ff', display: 'flex', alignItems: 'center', justifyContent: 'center', marginTop: '20px', borderRadius: '8px', border: '2px dashed #1890ff' }}>
                <p style={{ color: '#0050b3', fontWeight: 'bold' }}>[ Giả lập Bản đồ không gian PostGIS / GPS ]</p>
            </div>
        </div>
    );
}