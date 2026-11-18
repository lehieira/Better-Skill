---
name: rag-pipeline-architect
description: "Thiết kế pipeline RAG (Retrieval-Augmented Generation): chiến lược chunking giữ ngữ cảnh, metadata filtering theo tenant/quyền, hybrid search (vector + BM25), reranking và kiểm chứng trích dẫn (citation grounding). Dùng khi xây dựng hỏi-đáp tài liệu nội bộ."
---

# Skill: RAG Pipeline Architect

Xây dựng hệ thống truy xuất tri thức chính xác, tôn trọng phân quyền dữ liệu và hạn chế tối đa ảo giác (hallucination).

---

## 1. Kiến Trúc Ingestion & Chunking
- **Làm sạch & Giữ Cấu Trúc**: Bảo toàn tiêu đề mục (`H1/H2/H3`), bảng và ngữ cảnh cha khi tách đoạn (Semantic/Recursive chunking ~400–800 tokens, overlap 10–15%).
- **Metadata Bắt Buộc Trên Mỗi Chunk**: `doc_id`, `source_title`, `section_path`, `updated_at`, và **trường phân quyền (`tenant_id`, `visibility`, `allowed_roles`)**.

---

## 2. Truy Xuất & Bảo Mật Dữ Liệu
1. **Pre-Filtering Quyền Truy Cập Trước Khi Ranking**:
   - Bắt buộc lọc theo `tenant_id` / `allowed_roles` ngay tại tầng vector DB query — **tuyệt đối cấm để tài liệu người khác lọt vào context prompt** (chống IDOR qua RAG).
2. **Hybrid Search + Reranking**:
   - Kết hợp Vector similarity (ngữ nghĩa) + Keyword/BM25 (mã lỗi, tên hàm, mã sản phẩm chính xác).
   - Lấy top-K rộng (20–40 chunks) -> Rerank chọn top 5–8 chunks chất lượng cao đưa vào LLM.
3. **Citation Grounding**:
   - Yêu cầu model gắn mã trích dẫn `[doc_id#section]` cho từng khẳng định; nếu context không chứa câu trả lời thì từ chối trả lời thay vì đoán.
4. **Đo Lường Truy Xuất Độc Lập**: Đo riêng `Recall@K` / `MRR` của bộ retriever trước khi tinh chỉnh prompt sinh câu trả lời.
