// admin-web/src/pages/Dashboard.tsx
export default function Dashboard() {
    return (
        <div style={{ padding: '20px', backgroundColor: '#f0f2f5', borderRadius: '8px' }}>
            <h2>📊 Hệ Thống Quản Trị Trung Tâm (Dashboard)</h2>
            <p>Chào mừng Admin Dương Quốc Anh. Dưới đây là thống kê sự cố đô thị:</p>
            <div style={{ display: 'flex', gap: '20px', marginTop: '20px' }}>
                <div style={{ background: '#fff', padding: '20px', borderRadius: '8px', flex: 1, boxShadow: '0 2px 4px rgba(0,0,0,0.1)' }}>
                    <h3>🚨 Sự cố mới</h3>
                    <p style={{ fontSize: '24px', fontWeight: 'bold', color: '#ff4d4f' }}>12</p>
                </div>
                <div style={{ background: '#fff', padding: '20px', borderRadius: '8px', flex: 1, boxShadow: '0 2px 4px rgba(0,0,0,0.1)' }}>
                    <h3>🛠️ Đang xử lý</h3>
                    <p style={{ fontSize: '24px', fontWeight: 'bold', color: '#1890ff' }}>5</p>
                </div>
                <div style={{ background: '#fff', padding: '20px', borderRadius: '8px', flex: 1, boxShadow: '0 2px 4px rgba(0,0,0,0.1)' }}>
                    <h3>✅ Đã giải quyết</h3>
                    <p style={{ fontSize: '24px', fontWeight: 'bold', color: '#52c41a' }}>45</p>
                </div>
            </div>
        </div>
    );
}