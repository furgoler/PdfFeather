/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

#include "qpdflibwrapper.h"

#include <QFileInfo>

#include <qpdf/QPDFWriter.hh>
#include <qpdf/QPDFPageDocumentHelper.hh>
#include <qpdf/QPDFEmbeddedFileDocumentHelper.hh>
#include <qpdf/QUtil.hh>
#include <qpdf/Pl_StdioFile.hh>
// For getting knowledge of using QDPF lib, see examples in qpdf/test_*.cc and examples

QPDFLibWrapper::QPDFLibWrapper(QObject *parent) : QObject{parent}
{
    initQPDF();
}

QPDFLibWrapper::~QPDFLibWrapper()
{
   closeQPDF();
}

void QPDFLibWrapper::initQPDF()
{
    if (m_qpdf == nullptr) {
        m_qpdf = new QPDF();
    }
}
void QPDFLibWrapper::closeQPDF()
{
    if (m_qpdf != nullptr)
    {
        delete m_qpdf;
        m_qpdf = nullptr;
    }
}

void QPDFLibWrapper::loadpdf(const QString &file, const QString &password)
{
    closeQPDF();
    initQPDF();
    m_qpdf->processFile(file.toStdString().data(), password.toStdString().data());
}

bool QPDFLibWrapper::savepdf(const QString &file)
{
    try
    {
        // Save Pdf
        QPDFWriter w(*m_qpdf);
        w.setOutputFilename(file.toStdString().data());
        w.write();

        return true;
    }
    catch(const std::exception& ex)
    {
        // specific handling for all exceptions extending std::exception
        qDebug() << "QPDFLibWrapper::savepdf" << ex.what();
    }
    catch (...)
    {
        // The use of QPDFWriter would imply to create a temporary file a after closing QPDF and then rename the file
        // Instead of check this condition, it is used try/catch feature since this allows to capture other possible failures
        qDebug() << "QPDFLibWrapper::savepdf" << "Unknown exception";
    }

    return false;
}

QList<QString> QPDFLibWrapper::getEmbeddedFiles()
{
    QPDFEmbeddedFileDocumentHelper efdh(*m_qpdf);

    // Clear and fill new attachments on an empty list
    QList<QString> embbededfiles;
    for (auto const& [key, efoh] : efdh.getEmbeddedFiles())
    {
        //std::map<std::string, std::shared_ptr<QPDFFileSpecObjectHelper>> getEmbeddedFiles()
        // key is std::string
        // efoh is std::shared_ptr<QPDFFileSpecObjectHelper>
        embbededfiles.append(QString::fromUtf8(key));
    }

    return embbededfiles;
}

void QPDFLibWrapper::addEmbeddedFiles(const QList<QString> &paths)
{
    // Attachments
    QPDFEmbeddedFileDocumentHelper efdh(*m_qpdf);

    // Add/Replace new attachment files
    for (auto const& f : paths)
    {
        // Create object to be added
        QString keyfile(QString(QFileInfo(f).fileName()));
        QPDFFileSpecObjectHelper fs = QPDFFileSpecObjectHelper::createFileSpec(*m_qpdf, keyfile.toStdString(), f.toStdString());
        //fs.setDescription("some text");

        // Set Dates of attachment for their own files
        // PDF timestamp string: "D:yyyymmddhhmmss<z>" (see QPDF Library: QUtil::qpdf_time_to_pdf_time)
        QFileInfo fi(f);
        QPDFEFStreamObjectHelper efs = QPDFEFStreamObjectHelper(fs.getEmbeddedFileStream());
        efs.setCreationDate(QString("D:" + fi.fileTime(QFileDevice::FileBirthTime).toString("yyyyMMddhhmmss") + "<z>").toStdString());
        efs.setModDate(QString("D:" + fi.fileTime(QFileDevice::FileModificationTime).toString("yyyyMMddhhmmss") + "<z>").toStdString());

        // Add Attachement
        efdh.replaceEmbeddedFile(keyfile.toStdString(), fs);
    }
}

void QPDFLibWrapper::removeEmbeddedFiles(const QList<QString> &keys)
{
    // Attachments
    QPDFEmbeddedFileDocumentHelper efdh(*m_qpdf);

    // Remove attachemnt files (by key name)
    for (auto const& key : keys)
    {
        efdh.removeEmbeddedFile(key.toStdString());
    }
}


bool QPDFLibWrapper::exportEmbedFile(const QString &key, const QString &filename)
{
    QPDFEmbeddedFileDocumentHelper efdh(*m_qpdf);
    std::shared_ptr<QPDFFileSpecObjectHelper> fs = efdh.getEmbeddedFile(key.toStdString());

    if (fs != nullptr)
    {
        QPDFObjectHandle efs = fs->getEmbeddedFileStream();
        //QPDFEFStreamObjectHelper efsh = QPDFEFStreamObjectHelper(efs);
        //qDebug() << efsh.getSize();

        try
        {
            QUtil::FileCloser fc(QUtil::safe_fopen(filename.toStdString().data(), "wb"));
            auto save = std::make_shared<Pl_StdioFile>("save_attachment", fc.f);
            return (efs.pipeStreamData(save.get(), 0, qpdf_dl_all));
        }
        catch (const std::runtime_error& re)
        {
            // QUtil::safe_fopen throws std::runtime_error
            qDebug() << "QPDFLibWrapper::saveEmbedFile" << "runtime_error" << re.what();
        }
        catch(const std::exception& ex)
        {
            // specific handling for all exceptions extending std::exception
            qDebug() << "QPDFLibWrapper::saveEmbedFile" << "exception" << ex.what();
        }
        catch (...)
        {
            qDebug() << "QPDFLibWrapper::saveEmbedFile" << "Unknown exception";
        }
    }

    return false;
}

void QPDFLibWrapper::updateMedatadaInfo(const QString &key, const QString &value)
{
    // Standards property names: Title, Author, Subject, Keywords, Creator, Producer, CreationDate, ModDate, Trapped
    // In addition, custom properties can be added using this method

    QPDFObjectHandle trailer = m_qpdf->getTrailer();
    if (!trailer.hasKey("/Info")) trailer.replaceKey("/Info", m_qpdf->makeIndirectObject(QPDFObjectHandle::newDictionary()));
    QPDFObjectHandle info = trailer.getKey("/Info");

    info.replaceKey(
        (QString("/") + key).toLatin1().data(),
        QPDFObjectHandle::newString(value.toLatin1().data()));
}

void QPDFLibWrapper::updateMedatadaInfo(QMap<QString, QString> &metadata)
{
    // Standards property names: Title, Author, Subject, Keywords, Creator, Producer, CreationDate, ModDate, Trapped
    // In addition, custom properties can be added using this method

    QPDFObjectHandle trailer = m_qpdf->getTrailer();
    if (!trailer.hasKey("/Info")) trailer.replaceKey("/Info", m_qpdf->makeIndirectObject(QPDFObjectHandle::newDictionary()));
    QPDFObjectHandle info = trailer.getKey("/Info");

    for (QMap<QString, QString>::iterator it = metadata.begin(); it != metadata.end(); ++it)
    {
        info.replaceKey(
            (QString("/") + it.key()).toLatin1().data(),
            QPDFObjectHandle::newString(it.value().toLatin1().data()));
    }
}

int QPDFLibWrapper::getNumberOfPages()
{
    QPDFObjectHandle root = m_qpdf->getRoot();
    QPDFObjectHandle pages = root.getKey("/Pages");
    QPDFObjectHandle count = pages.getKey("/Count");
    return (count.getIntValue());
}

QPDFObjectHandle QPDFLibWrapper::createEmptyPage(int x_size, int y_size)
{
    // Example: Page Size A4 scale factor 2.84 {210 x 297 mm (Vertical A4)}
    QString page_def =
        QString("<<") +
        QString(" /Type /Page") +
        QString(" /MediaBox [0 0 ") + QString::number(x_size) + QString (" ") + QString::number(y_size) + QString("]") +
        QString(">>");

    return (m_qpdf->makeIndirectObject(QPDFObjectHandle::parse(page_def.toStdString())));
}

void QPDFLibWrapper::createEmptyPdf()
{
    m_qpdf->emptyPDF();
}

void QPDFLibWrapper::addEmptyPage(int x_size, int y_size)
{
    QPDFPageDocumentHelper dh(*m_qpdf);
    QPDFObjectHandle template_page = createEmptyPage(x_size, y_size);
    dh.addPage(template_page, false);
}

void QPDFLibWrapper::addPagesOfNames(
        QList<QString> names,
        int x_size,
        int y_size,
        int x_margin,
        int y_margin,
        int font_size,
        int interline,
        int font_size_header,
        const QString& header)
{
    QList<QPDFObjectHandle> pages;
    int num_items_per_page = (y_size - 2 * y_margin) / (font_size + interline);
    int num_pages = (names.size() / num_items_per_page) + 1;

    // Create empty template page
    QPDFObjectHandle template_page = createEmptyPage(x_size, y_size);

    // Create a font "F1" (inside resources Tree)
    QPDFObjectHandle font = m_qpdf->makeIndirectObject(
        "<<"
        " /Type /Font"
        " /Subtype /Type1"
        " /Name /F1"
        " /BaseFont /Helvetica"
        " /Encoding /WinAnsiEncoding"
        ">>"_qpdf);   // _qpdf is equivalent to QPDFObjectHandle::parse(xxx)
    QPDFObjectHandle rfont = QPDFObjectHandle::newDictionary();
    rfont.replaceKey("/F1", font);

    QPDFObjectHandle resources = QPDFObjectHandle::newDictionary();
    QPDFObjectHandle procset = "[/PDF /Text]"_qpdf;
    resources.replaceKey("/ProcSet", procset);
    resources.replaceKey("/Font", rfont);
    template_page.replaceKey("/Resources", resources);

    // Create text content in pages. Add all pages as a copy of my template page
    for (int i = 0; i < num_pages; i++) pages.append((template_page.shallowCopy()));

    QString header_content =
        QString("BT ") +
        // Font F1 Size 14
        QString("/F1 ") + QString::number(font_size_header) + QString(" ") +
        // Pos X,Y (0,0 is lower left corner)
        QString("Tf ") + QString::number(x_margin) + QString(" ") + QString::number(y_size - y_margin) + QString(" ") +
        // Text
        QString("Td (") + header + QString(") Tj ") +
        QString("ET\n");
    pages[0].addPageContents(
        QPDFObjectHandle::newStream(
            m_qpdf, header_content.toLatin1().data()),
            true);

    QString content;
    int page_index_previous = -1;
    int page_index = -1;
    int y_pos = -1;
    for (int i = 0; i < names.size(); i++)
    {
        page_index_previous = page_index;
        page_index = i / num_items_per_page;
        y_pos = page_index_previous == page_index ? y_pos - (font_size + interline) : y_size - y_margin - (font_size_header + interline);

        content =
            QString("BT ") +
            // Font F1 Size 12
            QString("/F1 ") + QString::number(font_size) + QString(" ") +
            // Pos X,Y (0,0 is lower left corner)
            QString("Tf ") + QString::number(x_margin) + QString(" ") + QString::number(y_pos) + QString(" ") +
            // Text
            QString("Td (") +
            QString::number(i + 1) + QString(". ") + names.at(i) +
            QString(") Tj ") +
            QString("ET\n");

        pages[page_index].addPageContents(
            QPDFObjectHandle::newStream(
                m_qpdf, content.toLatin1().data()),  // toLatin1 conversion (valid for accent marks)
                false);
    }

    QPDFPageDocumentHelper dh(*m_qpdf);
    for (int i = 0; i < pages.size(); i++) dh.addPage(pages.at(i), false);
}
