import { uploadImages } from './storageService';

/**
 * Sube una imagen QR a la carpeta 'qr-payments'
 * @param {File} file - archivo de imagen QR
 * @param {string|number} itemId - opcional, id del QrCodePayment
 * @returns {Promise<string>} URL de la imagen subida
 */
export async function uploadQrPaymentImage(file, itemId = 'new') {
    if (!file) throw new Error('No se seleccionó ningún archivo');
    const urls = await uploadImages(file, { folder: 'qr-payments', itemId });
    const url = urls?.[0];
    if (!url) throw new Error('No se recibió URL de la imagen QR');
    return url;
}
