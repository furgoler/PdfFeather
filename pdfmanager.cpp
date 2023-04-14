/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

#include "pdfmanager.h"

#include <QDebug>
#include <QFileInfo>
#include <QDateTime>
#include <QDir>
#include <QStandardPaths>
#include <QUuid>
#include <QDesktopServices>


PdfManager::PdfManager(PdfAttachmentModel *model, QObject *parent)
    : QObject{parent}
{
    m_attach_model = model;
    m_changes_saved = true;
    m_attachment_policy_level = 0;
    m_header_text = tr("Embedded Content:");

    m_temp_folder = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/.pdffeather";
    if (!QDir(m_temp_folder).exists()) QDir().mkdir(m_temp_folder);
    qDebug() << "Temporal Folder:" << m_temp_folder;

    m_qpdf_lib.createEmptyPdf();
}

PdfManager::~PdfManager()
{
    // Remove all files from temporary folder
    try
    {
        QDir dir(m_temp_folder);
        for(const QString &dirFile: dir.entryList()) {
            dir.remove(dirFile);
        }
    }
    catch(...) {}
}

QString PdfManager::getHeaderText()
{
    return m_header_text;
}

void PdfManager::setHeaderText(const QString &text)
{
    m_header_text = text;
}

int PdfManager::getAttachmentPolicy ()
{
    return m_attachment_policy_level;
}

void PdfManager::setAttachmentPolicy(int level)
{
    m_attachment_policy_level = level;
}

void PdfManager::pendingSaves(bool status)
{  
    m_changes_saved = !status;
    emit savedChanged();
}

void PdfManager::replaceMetadata(const QString &key, const QString &value)
{
    // Standards property names: Title, Author, Subject, Keywords, Creator, Producer, CreationDate, ModDate, Trapped
    // In addition, custom properties can be added using this method
    m_qpdf_lib.updateMedatadaInfo(key, value);
    pendingSaves(true);
}

void PdfManager::addEmbedFile(const QUrl &url)
{
    QList<QUrl> new_urls;
    new_urls.append(url);
    addEmbedFiles(new_urls);
}

void PdfManager::addEmbedFiles(const QList<QUrl> &files)
{
    QList<QString> currentembbededfiles;
    QList<QString> new_file_attachments;
    QList<QString> new_key_attachments;
    QString key;
    QString localfile;

    currentembbededfiles = m_attach_model->getData();
    for (auto const& url : files)
    {
        localfile = url.toLocalFile();
        key = url.fileName();
        if (!QFileInfo(localfile).isDir())
        {
            if (currentembbededfiles.contains(key)) m_attach_model->removeByKey(key);
            new_file_attachments.append(localfile);
            new_key_attachments.append(key);
        }
        else qDebug() << "Rejected:" << localfile << "is a folder";
    }
    m_attach_model->appendList(new_key_attachments);
    m_qpdf_lib.addEmbeddedFiles(new_file_attachments);
    if (new_file_attachments.size() >= 0) pendingSaves(true);
}

void PdfManager::removeEmbedFile(const QString &key)
{
    QList<QString> old_keys;
    old_keys.append(key);
    removeEmbedFiles(old_keys);
}

void PdfManager::removeEmbedFiles(const QList<QString> &keys)
{
    QList<QString> old_keys;
    QList<QString> currentembbededfiles = m_attach_model->getData();
    for (auto const& key : keys)
    {
        if (currentembbededfiles.contains(key))
        {
            m_attach_model->removeByKey(key);
            old_keys.append(key);
        }
    }
    m_qpdf_lib.removeEmbeddedFiles(old_keys);
    pendingSaves(old_keys.size() > 0);
}

bool PdfManager::saveEmbedFile(const QString &key, const QUrl &path)
{
    return (m_qpdf_lib.exportEmbedFile(key, path.toLocalFile() + "/" + key));
}

bool PdfManager::saveAllEmbedFiles(const QUrl &path)
{
    bool result = true;
    QList<QString> currentembbededfiles = m_attach_model->getData();
    for (auto const& key : currentembbededfiles)
    {
        result = result && (m_qpdf_lib.exportEmbedFile(key, path.toLocalFile() + "/" + key));
    }
    return result;
}

bool PdfManager::openEmbedFile(const QString &key)
{
    QFileInfo fi(key);
    QUuid uuid = QUuid::createUuid();
    QString random_str = uuid.toString(QUuid::WithoutBraces);
    random_str.truncate(8);
    QString tempfile = m_temp_folder + "/" + fi.baseName() + "-" + random_str + "." + fi.completeSuffix();

    qDebug() << "Open" << tempfile;
    if (m_qpdf_lib.exportEmbedFile(key, tempfile)) QDesktopServices::openUrl(QUrl(tempfile));
    else return false;

    return true;
}

void PdfManager::loadPdf(const QUrl &file, const QString &password)
{
    //QList<QString> embbededfiles;

    m_pdf_url = file;
    m_password = password;

    m_qpdf_lib.loadpdf(m_pdf_url.toLocalFile(), m_password);

    m_attach_model->clear();
    m_attach_model->appendList(m_qpdf_lib.getEmbeddedFiles());

    pendingSaves(false);
}

bool PdfManager::savePdf(const QUrl &file)
{

    bool new_file = m_pdf_url.isEmpty();
    bool result = false;    

    // Get timestamp for Metadata
    QString timestamp = "D:" + QDateTime::currentDateTime().toString("yyyyMMddhhmmss") + "<z>";
    if (new_file) m_qpdf_lib.updateMedatadaInfo("CreationDate", timestamp);
    m_qpdf_lib.updateMedatadaInfo("ModDate", timestamp);

    if (((m_attachment_policy_level == 1) && new_file) || (m_attachment_policy_level == 2))
    {
        // Create pages with a list of files, only for new Pdfs or for level 2
        m_qpdf_lib.addPagesOfNames(
                    m_attach_model->getData(),  // List of names to be addes
                    596, 843,                   // Page size <x>, <y>
                    50, 50,                     // Margin <x>, <y>
                    11,                         // Font size
                    6,                          // Interline gap
                    14,                         // Font size of header/introduction text
                    m_header_text               // Introduction text
                );              
    }
    else {
        // Do not add any page to the file. Note that, for new pdf, it is required an empty page
        if (new_file) {
            // empty page
            m_qpdf_lib.addEmptyPage(596, 843); // A4 size
        }
    }

    // Save Pdf
    result = m_qpdf_lib.savepdf(file.toLocalFile());

    pendingSaves(!result);
    return result;
}
