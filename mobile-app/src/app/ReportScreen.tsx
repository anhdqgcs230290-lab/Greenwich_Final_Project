// mobile-app/screens/ReportScreen.tsx
import React, { useState } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, ScrollView } from 'react-native';

export default function ReportScreen() {
    const [description, setDescription] = useState('');

    return (
        <ScrollView style={styles.container}>
            <Text style={styles.title}>🚨 Báo Cáo Sự Cố Đô Thị</Text>

            {/* Khung giả lập Camera/Upload ảnh */}
            <View style={styles.photoBox}>
                <Text style={styles.photoText}>📸 [ Bấm để chụp ảnh sự cố ]</Text>
                <Text style={styles.subText}>(AI sẽ tự động phân loại: ổ gà, đèn hỏng...)</Text>
            </View>

            {/* Khung giả lập Định vị GPS */}
            <View style={styles.gpsBox}>
                <Text style={styles.gpsText}>📍 Vị trí: Đang lấy tọa độ GPS từ thiết bị...</Text>
            </View>

            {/* Ô nhập mô tả */}
            <Text style={styles.label}>Chi tiết sự cố:</Text>
            <TextInput
                style={styles.input}
                placeholder="Nhập mô tả chi tiết (ví dụ: ổ gà sâu gây nguy hiểm)..."
                value={description}
                onChangeText={setDescription}
                multiline
            />

            {/* Nút gửi */}
            <TouchableOpacity style={styles.button} onPress={() => alert('Đã gửi báo cáo thành công lên hệ thống!')}>
                <Text style={styles.buttonText}>🚀 Gửi Báo Cáo Đến Chính Quyền</Text>
            </TouchableOpacity>
        </ScrollView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, padding: 20, backgroundColor: '#fff' },
    title: { fontSize: 22, fontWeight: 'bold', color: '#1890ff', marginBottom: 20, marginTop: 40, textAlign: 'center' },
    photoBox: { height: 150, backgroundColor: '#f5f5f5', justifyContent: 'center', alignItems: 'center', borderRadius: 8, borderWidth: 1, borderStyle: 'dashed', borderColor: '#d9d9d9', marginBottom: 15 },
    photoText: { color: '#595959', fontWeight: '600' },
    subText: { color: '#8c8c8c', fontSize: 12, marginTop: 4 },
    gpsBox: { padding: 15, backgroundColor: '#e6f7ff', borderRadius: 8, marginBottom: 15 },
    gpsText: { color: '#0050b3', fontWeight: '500' },
    label: { fontSize: 16, fontWeight: '600', marginBottom: 8, color: '#333' },
    input: { height: 100, borderColor: '#d9d9d9', borderWidth: 1, borderRadius: 8, padding: 10, textAlignVertical: 'top', marginBottom: 20 },
    button: { backgroundColor: '#1890ff', padding: 15, borderRadius: 8, alignItems: 'center' },
    buttonText: { color: '#fff', fontSize: 16, fontWeight: 'bold' },
});